import sys
import requests
import xml.etree.ElementTree as ET
from datetime import datetime
from pyspark.sql import Row
from awsglue.utils import getResolvedOptions
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.context import SparkContext
from awsglue.dynamicframe import DynamicFrame

# Glue job args
args = getResolvedOptions(sys.argv, ['JOB_NAME'])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# === CONFIG ===
rss_url = "https://www.reddit.com/r/italynews/.rss"
s3_output_path = "s3://tedxpresso-data-mp/reddit_feed/"
mongodb_collection = "reddit_feed"

# === FUNZIONE PARSING RSS ATOM ===
def fetch_reddit_rss_data(url):
    try:
        response = requests.get(url, headers={
            'User-Agent': 'Mozilla/5.0 (compatible; AWS Glue Job)'
        }, timeout=10)

        if response.status_code != 200:
            print(f"HTTP Error {response.status_code}")
            return []

        root = ET.fromstring(response.content)
        ns = {'atom': 'http://www.w3.org/2005/Atom'}
        entries = root.findall("atom:entry", ns)
        print(f"Trovati {len(entries)} elementi nel feed.")

        items = []
        for entry in entries:
            title = entry.findtext("atom:title", default="", namespaces=ns)

            link_el = entry.find("atom:link[@rel='alternate']", ns)
            if link_el is None:
                link_el = entry.find("atom:link", ns)
            link = link_el.attrib['href'] if link_el is not None else None

            published = entry.findtext("atom:published", default="", namespaces=ns)
            summary = entry.findtext("atom:content", default="", namespaces=ns)

            try:
                published_dt = datetime.strptime(published, "%Y-%m-%dT%H:%M:%S%z")
                published_str = published_dt.isoformat()
            except:
                published_str = None

            items.append({
                "title": title,
                "link": link,
                "published": published_str,
                "summary": summary
            })

        return items

    except Exception as e:
        print("Errore durante il parsing:", str(e))
        return []

# === FETCH RSS ===
rss_data = fetch_reddit_rss_data(rss_url)

if not rss_data:
    print("Nessun elemento trovato.")
    job.commit()
    sys.exit(0)

# === CONVERSIONE IN DATAFRAME ===
rows = [Row(**item) for item in rss_data]
rss_df = spark.createDataFrame(rows)
rss_df.printSchema()
rss_df.show(5, truncate=False)

# === SALVA SU S3 (come nel tuo codice) ===
rss_df.write.mode("overwrite").json(s3_output_path)

# === SALVA SU MONGODB (DynamicFrame, come nel tuo codice) ===
rss_df = rss_df.withColumnRenamed("link", "_id")  # MongoDB richiede _id univoco

rss_dynamic_frame = DynamicFrame.fromDF(rss_df, glueContext, "reddit_feed")
glueContext.write_dynamic_frame.from_options(
    rss_dynamic_frame,
    connection_type="mongodb",
    connection_options={
        "connectionName": "Mongodbatlas connection",
        "database": "unibg_tedx_2025",
        "collection": mongodb_collection,
        "ssl": "true",
        "ssl.domain_match": "false"
    }
)

job.commit()
