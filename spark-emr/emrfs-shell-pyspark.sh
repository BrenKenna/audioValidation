###############################################
###############################################
#
# Examples of somethings
# 
###############################################
###############################################


# Read a log file from S3 logging URI
hdfs dfs -cat s3://bk-spark-cluster-tf/spark/j-DHIV6JGGHIKY/containers/application_1666953345948_0001/container_1666953345948_0001_01_000001/stderr.gz \
    | gzip -d - \
    | less


# From pyspark: Alternative is just an os process :)
pyspark
path = 's3://bk-spark-cluster-tf/spark/j-DHIV6JGGHIKY/containers/application_1666953345948_0001/container_1666953345948_0001_01_000001/'
data = sc.binaryFiles(str(path + 'stderr.gz'))
data.first()

"""

- Works fine

(
    's3://bk-spark-cluster-tf/spark/j-DHIV6JGGHIKY/containers/application_1666953345948_0001/container_1666953345948_0001_01_000001/stderr.gz',
    b'\x1f\x8b\x08\x00\x00\x00...'
)
"""


# Decompress data
import gzip
import base64

output = data.first()
decompr = gzip.decompress(output[1]).decode('utf-8').split('\n')
len(decompr)
decompr[0:3]

"""

- Reads fine, better with objects. Likes of audio etc, different story unless already around

100

[
    '22/10/28 10:53:46 INFO SignalUtils: Registering signal handler for TERM',
   '22/10/28 10:53:46 INFO SignalUtils: Registering signal handler for HUP',
   '22/10/28 10:53:46 INFO SignalUtils: Registering signal handler for INT'
]
"""



#
import boto3
s3 = boto3.client('s3')
bucket = "bk-spark-cluster-tf"
prefix = "spark/j-DHIV6JGGHIKY/containers/application_1666953345948_0001/container_1666953345948_0001_01_000001/"
response = s3.list_objects(Bucket = bucket, Prefix = prefix)
response.keys()
response['Contents'][0].keys()


"""


- Response object
dict_keys(['ResponseMetadata', 'IsTruncated', 'Marker', 'Contents', 'Name', 'Prefix', 'MaxKeys', 'EncodingType'])


- Content objects
dict_keys(['Key', 'LastModified', 'ETag', 'Size', 'StorageClass', 'Owner'])

"""