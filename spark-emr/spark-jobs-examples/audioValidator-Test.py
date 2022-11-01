# Import modules
import os, sys, boto3, shutil
import json
import matplotlib.pyplot as plt
import pandas as pd


# Get session
import pyspark
from pyspark.sql import SparkSession
spark = SparkSession.builder.getOrCreate()
sc = spark.sparkContext


# Set numba cache dir before librosa import
os.environ["NUMBA_CACHE_DIR"] = "/tmp/NUMBA_CACHE_DIR/"
from audioValidator.generator import generator
from audioValidator.results import results
from audioValidator.comparator import comparator
from audioValidator.utils import utils


# s3 config
import boto3
bucket = "band-cloud-audio-validation"
prefix = "real/"
s3_client = boto3.client('s3')
response = s3_client.list_objects(Bucket = bucket, Prefix = prefix)


# Setup work
toDo = []
for obj in response["Contents"]:
  outPath = str('./' + os.path.dirname(obj['Key']) + "/" + os.path.basename(obj['Key']).replace('.wav', '') )
  item = (bucket, obj['Key'], outPath)
  toDo.append(item)


# Run analysis
# outMap = list(map( utils.runFetchAndClassify, toDo ))
toDo_spark = sc.parallelize(toDo)
output = toDo_spark.map(utils.runFetchAndClassify).collect()
[ print(i["Track"] + " = " + str(i["Label"])) for i in output ]