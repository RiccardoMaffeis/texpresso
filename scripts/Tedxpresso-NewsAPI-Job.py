import sys
import os
import requests
import json

from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from awsglue.context import GlueContext
from pyspark.context import SparkContext
from pyspark.sql import SparkSession, Row
from pyspark.sql.types import StructType, StructField, StringType, TimestampType
from awsglue.dynamicframe import DynamicFrame

# Parametri passati al job
args = getResolvedOptions(sys.argv, ['JOB_NAME', 'NEWSAPI_KEY', 'S3_OUTPUT_PATH', 'QUERY', 'PAGES'])

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session

# Estrai parametri
api_key = args['NEWSAPI_KEY']
query = args['QUERY']
pages = int(args['PAGES'])
output_path = args['S3_OUTPUT_PATH']

# Funzione per chiamata API
def fetch_news(page):
    url = 'https://newsapi.org/v2/everything'
    params = {
        'q': query,
        'language': 'it',
        'pageSize': 100,
        'page': page,
        'apiKey': api_key
    }
    response = requests.get(url, params=params)
    if response.status_code != 200:
        raise Exception(f"Errore API ({response.status_code}): {response.text}")
    return response.json().get('articles', [])

# Recupera articoli
articles = []
for p in range(1, pages + 1):
    fetched = fetch_news(p)
    if not fetched:
        break
    articles.extend(fetched)

# Trasforma in RDD di Row
rows = [Row(
    source=art.get('source', {}).get('name'),
    author=art.get('author'),
    title=art.get('title'),
    description=art.get('description'),
    url=art.get('url'),
    publishedAt=art.get('publishedAt'),
    content=art.get('content')
) for art in articles]

rdd = sc.parallelize(rows)

df = spark.createDataFrame(rdd)

# Converti publishedAt in Timestamp
from pyspark.sql.functions import to_timestamp

df = df.withColumn('publishedAt', to_timestamp('publishedAt'))

# Salva su S3 in formato JSON
(df.write
   .mode('overwrite')
   .json(output_path)
)
print(f"✅ Scritti {df.count()} articoli su {output_path}")

# Scrittura su MongoDB usando lo stesso approccio degli altri script
write_opts = {
    "connectionName": "Mongodbatlas connection",  # nome della connessione definita in Glue
    "database": "unibg_tedx_2025",
    "collection": "newsAPI_files",
    "ssl": "true",
    "ssl.domain_match": "false"
}

try:
    dyf = DynamicFrame.fromDF(df, glueContext, "news_dynframe")
    glueContext.write_dynamic_frame.from_options(
        frame=dyf,
        connection_type="mongodb",
        connection_options=write_opts
    )
    print("✅ Articoli scritti con successo su MongoDB.")
except Exception as e:
    print(f"❌ Errore durante la scrittura su MongoDB: {e}")
