# Import modules
import os, sys, boto3, shutil
from datetime import datetime
import argparse
import json
import matplotlib.pyplot as plt
import pandas as pd


# Import pyspark modules: application_1668262260155_0007
import pyspark
from pyspark.sql import SparkSession
from pyspark.sql.functions import *
from pyspark.sql.types import *


# Fetch session etc
sys.stdout.write('\n\nFetching session\n')
spark = SparkSession.builder.getOrCreate()
sc = spark.sparkContext

# Help page
parser = argparse.ArgumentParser(
    description = "Calculate genotype dosages per loci across sample set.",
    formatter_class = argparse.RawTextHelpFormatter
)

# Arguments
parser.add_argument("-d", "--data", action = 'store', type = str, help = "Input data\n")
parser.add_argument("-j", "--jobKey", action = 'store', type = str, help = "Job key\n")
args = parser.parse_args()

# Exit if key argument are not supplied
if args.data == None or args.jobKey == None:

	# Exit if no table is provided
	print('\n\nExiting, key variables not provided. Required arguments are input data and an indentifier for this task')
	parser.print_help()
	sys.exit()

# Otherwise proceed
else:
    data = args.data
    jobKey = args.jobKey
    sys.stdout.write(
        '\n\nProceeding with Data = ' + 
          data + ', and JobKey = ' + 
          jobKey + '\n'
    )

# Proceed with task vars
# data="s3://aws-roda-hcls-datalake/thousandgenomes_dragen/var_nested/chrom=chr21/20210721_220854_00027_s6m5m_fab42b02-6a3b-4c6c-9bf2-2a3da032fa01"
partKey = os.path.dirname(data).split('/')[-1]
partID = os.path.basename(data)
chrom = partKey.split('=')[-1]
outName = str(partKey + '/' + partID)
tableSuffix = str(chrom + '_' + str(jobKey))
now = datetime.now().ctime()
sys.stdout.write(
    '\n\nAnalyzing: ' + str(chrom) +
    '\nReading inputdata: "' + str(data) +
    '\nPartitionKey, ID: ' + str(partKey) + ", " + str(partID)  +
    '"\nResults destined for = "' + str(outName) +
    '"\nStarted at: "' + now + '"\n\n'
)

##############################################################
##############################################################
#
# Explode Data by Sample & Construct Loci Table
#
##############################################################
##############################################################


# Collect here breaks later methods,
#  because results are a list of Rows
data = spark.read.orc(data)


#
# Explode samples & get dose per site
# Cause of memory broadcast error comes here, not sure about read
#  Collection causes OOM                                                                             
# java.lang.OutOfMemoryError: Java heap space
# -XX:OnOutOfMemoryError="kill -9 %p"
#   Executing /bin/sh -c "kill -9 4331"...
sys.stdout.write('\n\nExploding sites by sample\n')
dataSampExplode = data.select(
    data.variant_id,
    data.pos, data.ref,
    data.alt,
    explode(data.samples).alias('samples')
)
gtExplodeTableName = str('gtExplode_' + tableSuffix)
dataSampExplode.createOrReplaceTempView(gtExplodeTableName)
sampleLociSum = spark.sql('''
SELECT
  variant_id, pos, ref, alt, samples.id,
  aggregate(
    samples.gts, 0,
    (acc, value) -> acc + value
  ) AS genoSum
FROM ''' + gtExplodeTableName + '''
ORDER BY pos ASC
;
''').repartition(200).persist()
sys.stdout.write('\n\nGene Exploder Repartition + Sort: ' + datetime.now().ctime() + ' \n')

# Describe results
dataSum = data.describe()
dataSum.show() # Min = 5031637; Max = 46699951; Size = 41,668,314; #-5KB = 4166
sys.stdout.write('\n\nGene Exploder Show Summary: ' + datetime.now().ctime() + ' \n')


# Create regions
minMax = dataSum.select(dataSum.pos).collect()[-2::]
minLoci = int(minMax[0]['pos'])
maxLoci = int(minMax[1]['pos'])
size = (maxLoci - minLoci)
sizeInc = 10000

data = []
startLoci = int(minMax[0]['pos'])
endLoci = (startLoci + sizeInc)
iter = 0
while (startLoci < maxLoci) and (endLoci < maxLoci):
  row = (iter, startLoci, endLoci, (endLoci-startLoci))
  startLoci = int(endLoci + 1)
  endLoci = int(endLoci + sizeInc)
  data.append(row)
  iter += 1
  if endLoci >= maxLoci:
    row = (iter, startLoci, maxLoci, (maxLoci-startLoci))


# Summarize loci
sys.stdout.write(
    '\n\nSanity Checking loci\n' +
    '\n\nSize: ' + str(size) + '\n' +
    '\n\nN Regions: ' + str(len(data)) + '\n' +
    '\n\nFirst Few Records:\n' + str(data[0:3]) + '\n' +
    '\n\nLast Few Records:\n' + str(data[-4:-1]) + '\n'
)


# Configure regions
sys.stdout.write('\n\nCreating RDF from Dataset\n')
dataRDD = spark.sparkContext.parallelize(data)
dataSchema = StructType([
  StructField("Loci_ID", IntegerType(), True),
  StructField("StartLoci", IntegerType(), True),
  StructField("EndLoci", IntegerType(), True),
  StructField("LociSize", IntegerType(), True)
])
regionsDF = spark.createDataFrame(
  dataRDD,
  schema = dataSchema
)
sys.stdout.write('\n\nRDD from Regions: ' + datetime.now().ctime() + ' \n')


##############################################################
##############################################################
#
# Sum Genotypes, Samples & Variants per Loci
# 
# References- RDD.persist common :
# - https://0x0fff.com/spark-memory-management/
# - https://stackoverflow.com/questions/63151326/rdd-warning-not-enough-space-to-cache-rdd-in-memory
# - https://stackoverflow.com/questions/33162018/not-enough-space-to-cache-rdd-in-memory-warning
# 
##############################################################
##############################################################


# Collapse dosage per loci
sys.stdout.write('\n\nCreating Views for Datasets\n')
genoTableName = str('GenotypeDose_' + tableSuffix)
lociTableName = str('Loci_' + tableSuffix)
sampleLociSum.createOrReplaceTempView(genoTableName)
regionsDF.createOrReplaceTempView(lociTableName)


# Counts per genotype
sys.stdout.write('\n\nQuerying Loci Dose\n')
regionalGroupDose = spark.sql('''
SELECT
  ''' + lociTableName + '''.StartLoci, ''' + lociTableName + '''.EndLoci,
  COUNT(DISTINCT ''' + genoTableName + '''.variant_id) as VariantCount,
  COUNT(DISTINCT ''' + genoTableName + '''.id) as SampleCount,
  SUM(''' + genoTableName + '''.genoSum) as LociDose,
  SUM(CASE WHEN ''' + genoTableName + '''.genoSum = 1 THEN 1 ELSE 0 END) as LociHetDose,
  SUM(CASE WHEN ''' + genoTableName + '''.genoSum = 2 THEN 1 ELSE 0 END) as LociHomDose,
  SUM(CASE WHEN ''' + genoTableName + '''.genoSum >= 3 THEN 1 ELSE 0 END) as LociCNVDose,
  SUM(CASE WHEN ''' + genoTableName + '''.genoSum <= 0 THEN 1 ELSE 0 END) as LociNullDose
FROM ''' + lociTableName + '''
INNER JOIN ''' + genoTableName + ''' 
  ON ''' + genoTableName + '''.pos >= ''' + lociTableName + '''.StartLoci
   AND ''' + genoTableName + '''.pos <= ''' + lociTableName + '''.EndLoci
GROUP BY ''' + lociTableName + '''.StartLoci, ''' + lociTableName + '''.EndLoci
ORDER BY ''' + lociTableName + '''.StartLoci ASC
;
''').persist()
sys.stdout.write('\n\nPersist Final Results: ' + datetime.now().ctime() + ' \n')
regionalGroupDose.printSchema()
regionalGroupDose.describe([
  'VariantCount', 'SampleCount', 'LociDose', 'LociHetDose',
  'LociHomDose', 'LociCNVDose', 'LociNullDose'
]).show()
sys.stdout.write('\n\nSummarize Final Results: ' + datetime.now().ctime() + ' \n')
sampleLociSum.write.csv("s3://band-cloud-audio-validation/1kg-genoDose-ETL/csvs/site/" + jobKey + "/" + outName)
sys.stdout.write('\n\nSite-CSV Write: ' + datetime.now().ctime() + ' \n')
sampleLociSum.unpersist()
sys.stdout.write('\n\nSite-CSV Clear: ' + datetime.now().ctime() + ' \n')
regionalGroupDose.show(10)
sys.stdout.write('\n\nResults Show 10: ' + datetime.now().ctime() + ' \n')

#
# Store results:
#  => Also hangs
#  => Should really later merged into proper DB, & 
#      not assume all is well with the below
#  => RDF.write(). JDBC/CSV/JSON-Compression
#  => write.parquet(tgt, compression, partitionBy)
tgtBucketPath = str("s3://band-cloud-audio-validation/1kg-genoDose-ETL/" + outName)
sys.stdout.write('\n\n\nWriting results to: "' + tgtBucketPath + '"\n')
regionalGroupDose.write.parquet(
    tgtBucketPath,
    compression = "snappy"
)
sys.stdout.write('\n\nResults Write: ' + datetime.now().ctime() + ' \n')
regionalGroupDose.write.csv("s3://band-cloud-audio-validation/1kg-genoDose-ETL/csvs/loci/"  + jobKey + "/" + outName)
sys.stdout.write('\n\nResults Write CSV: ' + datetime.now().ctime() + ' \n')
regionalGroupDose.unpersist()
sys.stdout.write('\n\nResults Clear: ' + datetime.now().ctime() + ' \n')