# pyspark
import pyspark
from pyspark.sql import SparkSession
spark = SparkSession.builder \
                    .master('local[1]') \
                    .appName('AudioValidator.com') \
                    .getOrCreate()
sc = spark.session


# Import modules
import os, sys, boto3
import json
import matplotlib.pyplot as plt
import pandas as pd


# Audio validator
from audioValidator.generator import generator
from audioValidator.results import results
from audioValidator.comparator import comparator
from audioValidator.utils import utils


# s3 config
bucket = "band-cloud-audio-validation"
s3_client = boto3.client('s3')


# Configure analysis list
dataDir = '/home/hadoop/examples'
toDo = []
for track in os.listdir(dataDir):
  trackName = track.replace('.wav', '')
  toDo.append( (trackName, track) )



# Options: foreach, map
# outMap = list(map( utils.classifyAudioSignal_fromTuple, toDo ))
toDo_spark = sc.parallelize(toDo)
output = toDo_spark.map(utils.classifyAudioSignal_fromTuple).collect()



response = s3_client.upload_file(file_name, bucket, object_name)