import sys
import json
import pyspark
from pyspark.sql.functions import col, collect_list, explode, struct
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame

# ----- READ PARAMETERS -----
args = getResolvedOptions(sys.argv, ['JOB_NAME'])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# ----- LOAD MAIN TEDX DATASET -----
tedx_dataset_path = "s3://tedxpresso-data-mp/final_list.csv"
tedx_dataset = spark.read \
    .option("header","true") \
    .option("quote", "\"") \
    .option("escape", "\"") \
    .csv(tedx_dataset_path)

# FILTER ITEMS WITH NULL POSTING KEY
count_items = tedx_dataset.count()
count_items_null = tedx_dataset.filter("id is not null").count()
print(f"Number of items from RAW DATA {count_items}")
print(f"Number of items from RAW DATA with NOT NULL KEY {count_items_null}")

# ----- LOAD DETAILS -----
details_dataset_path = "s3://tedxpresso-data-mp/details.csv"
details_dataset = spark.read \
    .option("header","true") \
    .option("quote", "\"") \
    .option("escape", "\"") \
    .csv(details_dataset_path) \
    .withColumnRenamed("interalId", "internal_id")

details_dataset = details_dataset.select(
    col("id").alias("id_ref"),
    col("description"),
    col("duration"),
    col("publishedAt"),
    col("internal_id")
)

# ----- JOIN DETAILS TO MAIN TEDX -----
tedx_dataset_main = tedx_dataset.join(
    details_dataset,
    tedx_dataset.id == details_dataset.id_ref,
    "left"
).drop("id_ref")

# ----- LOAD TAGS AND AGGREGATE -----
tags_dataset_path = "s3://tedxpresso-data-mp/tags.csv"
tags_dataset = spark.read.option("header","true").csv(tags_dataset_path)
tags_dataset_agg = tags_dataset.groupBy(
    col("id").alias("id_ref")
).agg(
    collect_list("tag").alias("tags")
)
tedx_dataset_agg = tedx_dataset_main.join(
    tags_dataset_agg,
    tedx_dataset_main.id == tags_dataset_agg.id_ref,
    "left"
).drop("id_ref")

# ----- LOAD IMAGES + ENRICH DETAILS -----
images_dataset = spark.read.option("header", "true").csv("s3://tedxpresso-data-mp/images.csv") \
    .withColumnRenamed("url", "image_url")

final_list_extra = spark.read.option("header", "true").csv("s3://tedxpresso-data-mp/final_list.csv") \
    .withColumnRenamed("url", "video_url") \
    .withColumnRenamed("speakers", "speaker") \
    .select("id", "title", "speaker", "video_url")

details_full = details_dataset.join(
    images_dataset,
    details_dataset.id_ref == images_dataset.id,
    "left"
).drop(images_dataset.id).join(
    final_list_extra,
    details_dataset.id_ref == final_list_extra.id,
    "left"
).drop(final_list_extra.id)

# ----- LOAD RELATED VIDEOS LIST -----
related_videos_dataset_path = "s3://tedxpresso-data-mp/related_videos.csv"
related_videos_dataset = spark.read.option("header","true").csv(related_videos_dataset_path)
related_videos_dataset_agg = related_videos_dataset.groupBy(
    col("id").alias("id_ref")
).agg(
    collect_list("related_id").alias("related_ids")
)

# ----- EXPLODE RELATED IDS TO LOOKUP FULL DETAILS -----
exploded = related_videos_dataset_agg.select(
    col("id_ref").alias("main_id"),
    explode("related_ids").alias("related_internal_id")
)

related_with_details = exploded.join(
    details_full,
    exploded.related_internal_id == details_full.internal_id,
    "left"
).filter(
    col("internal_id").isNotNull()
)

# ----- DEDUPLICATE RELATED VIDEOS per main_id + internal_id -----
related_with_details_unique = related_with_details.dropDuplicates([
    "main_id", "internal_id"
])

# ----- AGGREGATE DEDUPLICATED RELATED DETAILS -----
related_aggregated = related_with_details_unique.groupBy("main_id").agg(
    collect_list(
        struct(
            col("id_ref").alias("id"),
            col("internal_id"),
            col("title"),
            col("speaker"),
            col("video_url"),
            col("description"),
            col("duration"),
            col("publishedAt"),
            col("image_url")
        )
    ).alias("related_videos_details")
)

# ----- JOIN FINAL TEDX DATASET WITH RELATED STRUCT -----
tedx_dataset_final = tedx_dataset_agg.join(
    related_aggregated,
    tedx_dataset_agg.id == related_aggregated.main_id,
    "left"
).drop("main_id").withColumnRenamed("id", "_id")

# ----- SAVE TO MONGODB -----
write_mongo_options = {
    "connectionName": "Mongodbatlas connection",
    "database": "unibg_tedx_2025",
    "collection": "tedx_data",
    "ssl": "true",
    "ssl.domain_match": "false"
}

tedx_dataset_dynamic_frame = DynamicFrame.fromDF(tedx_dataset_final, glueContext, "nested")
glueContext.write_dynamic_frame.from_options(
    tedx_dataset_dynamic_frame,
    connection_type="mongodb",
    connection_options=write_mongo_options
)

job.commit()
