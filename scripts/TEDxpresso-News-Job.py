import json
import requests
from urllib.parse import urlencode
from datetime import datetime
from pyspark.sql import SparkSession, Row
from awsglue.context import GlueContext
from awsglue.utils import getResolvedOptions
from awsglue.dynamicframe import DynamicFrame
import sys

# === 1. Leggi parametri passati dal Glue Job ===
args = getResolvedOptions(sys.argv, ['NEWS_API_KEY', 'S3_OUTPUT_PATH'])
api_key     = args['NEWS_API_KEY']
output_path = args['S3_OUTPUT_PATH']

# === 2. Inizializza Spark e Glue ===
spark       = SparkSession.builder.getOrCreate()
glueContext = GlueContext(spark.sparkContext)

# === 3. Chiamata all’API NewsData.io ===
base_url = "https://newsdata.io/api/1/news"
params = {
    "apikey": api_key,
    "country": "it",
    "language": "it",
}

response = requests.get(f"{base_url}?{urlencode(params)}")
if response.status_code != 200:
    raise Exception(f"❌ NewsData.io API error {response.status_code}: {response.text}")

data = response.json()
articles = data.get("results", [])

# === 4. Aggiungi campo 'tags' usando 'category' ===
enriched = []
for article in articles:
    category = article.get("category")
    article["tags"] = [category] if category else ["Uncategorized"]
    enriched.append(article)

# === 5. Salva su S3 e MongoDB ===
if enriched:
    # Crea un RDD JSON per inferire schema correttamente
    json_rdd = spark.sparkContext.parallelize([json.dumps(a) for a in enriched])
    df       = spark.read.json(json_rdd)


    s3_path = f"{output_path}/news_json/"
    df.write.mode("overwrite").json(s3_path)
    print(f"✅ {df.count()} articoli salvati su {s3_path}")

    # Salvataggio su MongoDB
    write_opts = {
        "connectionName":    "Mongodbatlas connection",
        "database":          "unibg_tedx_2025",
        "collection":        "news_files",
        "ssl":               "true",
        "ssl.domain_match":  "false"
    }

try:
    dyf = DynamicFrame.fromDF(df, glueContext, "nested")
    glueContext.write_dynamic_frame.from_options(
        frame=dyf,
        connection_type="mongodb",
        connection_options=write_opts
    )
    print("✅ Articoli scritti con successo su MongoDB.")
except Exception as e:
    print(f"❌ Errore durante la scrittura su MongoDB: {e}")
    
else:
    print("⚠️ Nessun articolo da salvare.")
