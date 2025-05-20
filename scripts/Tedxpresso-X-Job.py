import sys
import json
import requests
from pyspark.context import SparkContext
from pyspark.sql import SparkSession
from awsglue.context import GlueContext
from awsglue.utils import getResolvedOptions
from awsglue.job import Job

# --- 1) Parametri di job Glue (ora includiamo anche 'query') ---
args = getResolvedOptions(
    sys.argv,
    ['JOB_NAME', 's3_output_path', 'api_endpoint', 'api_key', 'query']
)

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# --- 2) Headers e params per 1 singola richiesta di 2 tweet matching la query ---
headers = {
    'Authorization': f'Bearer {args["api_key"]}',
    'Accept': 'application/json'
}
params = {
    'query': args['query'],        # stringa di ricerca, es. "data",
    'tweet.fields': 'id,text',
    'max_results': 2
}

# --- 3) Chiamata all’API X ---
response = requests.get(args['api_endpoint'], headers=headers, params=params, timeout=30)
response.raise_for_status()
records = response.json().get('data', [])

# --- 4) Creazione DataFrame Spark da lista di dizionari ---
rdd = sc.parallelize(records)
df = spark.read.json(rdd)

# --- 5) Salvataggio in JSON in un solo file su S3 ---
(
    df
    .repartition(1)               # 1 partizione = 1 file
    .write
    .mode('overwrite')
    .json(args['s3_output_path'])
)

job.commit()
