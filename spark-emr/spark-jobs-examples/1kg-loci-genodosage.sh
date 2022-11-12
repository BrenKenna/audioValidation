###########################
# 
# Run Dosage Calc
# 
###########################


# application_1667990485131_0004
pyspark --master yarn
from pyspark.sql.functions import *
from pyspark.sql.types import *


# Fetch & scope out data
data="s3://aws-roda-hcls-datalake/thousandgenomes_dragen/var_nested/chrom=chr21/20210721_220854_00027_s6m5m_fab42b02-6a3b-4c6c-9bf2-2a3da032fa01"
data = spark.read.orc(data)

# Explode samples & get dose per site
dataSampExplode = data.select(data.variant_id, data.pos, data.ref, data.alt, explode(data.samples).alias('samples'))
dataSampExplode.createOrReplaceTempView('gtExplode')
sampleLociSum = spark.sql('''
SELECT
  variant_id, pos, ref, alt, samples.id,
  aggregate(
    samples.gts, 0,
    (acc, value) -> acc + value
  ) AS genoSum
FROM gtExplode;
''')


# Create regions: Create DF from 1k increments
dataSum = data.describe()
dataSum.show() # Min = 5031637; Max = 46699951; Size = 41,668,314; #-5KB = 4166

minLoci = 5031637
maxLoci = 46699951
size = (maxLoci - minLoci)
sizeInc = 10000

data = []
startLoci = 5031637
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


len(data)
data[0:3]
data[-4:-1]

'''

4166
[(0, 5031637, 5041637, 10000), (1, 5041638, 5051637, 9999), (2, 5051638, 5061637, 9999)]
[(4162, 46651638, 46661637, 9999), (4163, 46661638, 46671637, 9999), (4164, 46671638, 46681637, 9999)]

'''



# Configure regions
dataRDD = spark.sparkContext.parallelize(data)
dataSchema = StructType([
  StructField("Loci_ID", IntegerType(), True),
  StructField("StartLoci", IntegerType(), True),
  StructField("EndLoci", IntegerType(), True),
  StructField("LociSize", IntegerType(), True)
])

regionsDF = spark.createDataFrame(dataRDD, schema = dataSchema)
regionsDF.printSchema()
regionsDF.describe().show()


# Collapse dosage per loci
sampleLociSum.createOrReplaceTempView('GenotypeDose')
regionsDF.createOrReplaceTempView('Loci')

regionalBurden = spark.sql('''
SELECT
  Loci.StartLoci, Loci.EndLoci, SUM(GenotypeDose.genoSum) as LociDose,
  COUNT(DISTINCT GenotypeDose.variant_id) as VariantCount, COUNT(DISTINCT GenotypeDose.id) as SampleCount
FROM Loci
INNER JOIN GenotypeDose 
  ON GenotypeDose.pos >= Loci.StartLoci AND GenotypeDose.pos <= Loci.EndLoci
GROUP BY Loci.StartLoci, Loci.EndLoci
ORDER BY Loci.StartLoci ASC
;
''')
regionalBurden.printSchema()
regionalBurden.show(20)


'''

- Query worked fine, but initially limited 1000 samples on a 1K sample table lol

+---------+--------+--------+------------+-----------+                          
|StartLoci| EndLoci|LociDose|VariantCount|SampleCount|
+---------+--------+--------+------------+-----------+
| 41565341|41570340|    1465|           1|       1000|
+---------+--------+--------+------------+-----------+


- Results for 10/86

+---------+--------+--------+------------+-----------+                          
|StartLoci| EndLoci|LociDose|VariantCount|SampleCount|
+---------+--------+--------+------------+-----------+
| 41375340|41380340|    1443|           1|       1134|
| 41430341|41435340|    5022|           1|       2959|
| 41440341|41445340|    2453|           1|       1918|
| 41515341|41520340|    3747|           1|       2654|
| 41565341|41570340|    3803|           1|       2595|
| 41605341|41610340|     499|           1|        467|
| 41620341|41625340|    2445|           1|       1845|
| 41665341|41670340|    3192|           1|       2266|
| 41690341|41695340|    2026|           1|       1656|
| 41695341|41700340|    2796|           1|       2161|
+---------+--------+--------+------------+-----------+
only showing top 10 rows



- Full dataset broke cluster, but resolved 15:41 -> 15:52 (~10mins)

22/11/09 15:41:54 WARN MemoryStore: Not enough space to cache broadcast_9 in memory! (computed 1150.8 MiB so far)
22/11/09 15:41:54 WARN BlockManager: Persisting block broadcast_9 to disk instead.
22/11/09 15:42:31 WARN MemoryStore: Not enough space to cache broadcast_9 in memory! (computed 1150.8 MiB so far)

+---------+-------+--------+------------+-----------+                           
|StartLoci|EndLoci|LociDose|VariantCount|SampleCount|
+---------+-------+--------+------------+-----------+
|  5031637|5041637|     757|          11|        533|
|  5041638|5051637|     141|           8|        122|
|  5051638|5061637|     803|          14|        562|
|  5061638|5071637|    3966|          15|       1431|
|  5071638|5081637|     364|           8|        265|
|  5081638|5091637|    6482|           5|       3196|
|  5091638|5101637|    1241|          21|        844|
+---------+-------+--------+------------+-----------+
only showing top 20 rows

'''



# Counts per genotype
regionalGroupDose = spark.sql('''
SELECT
  Loci.StartLoci, Loci.EndLoci,
  COUNT(DISTINCT GenotypeDose.variant_id) as VariantCount,
  COUNT(DISTINCT GenotypeDose.id) as SampleCount,
  SUM(GenotypeDose.genoSum) as LociDose,
  SUM(CASE WHEN GenotypeDose.genoSum = 1 THEN 1 ELSE 0 END) as LociHetDose,
  SUM(CASE WHEN GenotypeDose.genoSum = 2 THEN 1 ELSE 0 END) as LociHomDose,
  SUM(CASE WHEN GenotypeDose.genoSum >= 3 THEN 1 ELSE 0 END) as LociCNVDose,
  SUM(CASE WHEN GenotypeDose.genoSum <= 0 THEN 1 ELSE 0 END) as LociNullDose
FROM Loci
INNER JOIN GenotypeDose 
  ON GenotypeDose.pos >= Loci.StartLoci AND GenotypeDose.pos <= Loci.EndLoci
GROUP BY Loci.StartLoci, Loci.EndLoci
ORDER BY Loci.StartLoci ASC
;
''')
regionalGroupDose.printSchema()
regionalGroupDose.describe([
  'VariantCount', 'SampleCount', 'LociDose', 'LociHetDose',
  'LociHomDose', 'LociCNVDose', 'LociNullDose'
]).show()
regionalGroupDose.show(10)

'''

- Broke again, 15:57 -> 16:06, next show(10) 16:07 -> 

22/11/09 15:57:46 WARN MemoryStore: Not enough space to cache broadcast_15 in memory! (computed 1150.8 MiB so far)
22/11/09 15:57:46 WARN BlockManager: Persisting block broadcast_15 to disk instead.
22/11/09 15:58:23 WARN MemoryStore: Not enough space to cache broadcast_15 in memory! (computed 1150.8 MiB so far)


- Broke again with show(10) 16:07 -> 16:17

[Stage 35:>                                                         (0 + 3) / 3]
22/11/09 16:07:47 WARN MemoryStore: Not enough space to cache broadcast_24 in memory! (computed 1150.8 MiB so far)
22/11/09 16:07:47 WARN BlockManager: Persisting block broadcast_24 to disk instead.
22/11/09 16:08:24 WARN MemoryStore: Not enough space to cache broadcast_24 in memory! (computed 1150.8 MiB so far)

+---------+-------+------------+-----------+--------+-----------+-----------+-----------+------------+
|StartLoci|EndLoci|VariantCount|SampleCount|LociDose|LociHetDose|LociHomDose|LociCNVDose|LociNullDose|
+---------+-------+------------+-----------+--------+-----------+-----------+-----------+------------+
|  5031637|5041637|          11|        533|     757|        443|        157|          0|           0|
|  5041638|5051637|           8|        122|     141|        107|         17|          0|           0|
|  5051638|5061637|          14|        562|     803|        343|        230|          0|           0|
|  5061638|5071637|          15|       1431|    3966|        642|       1599|         42|           0|
|  5071638|5081637|           8|        265|     364|        330|         17|          0|           0|
|  5081638|5091637|           5|       3196|    6482|         78|       3202|          0|           0|
|  5091638|5101637|          21|        844|    1241|        583|        329|          0|           0|
|  5101638|5111637|          14|        129|     170|         90|         40|          0|           0|
|  5111638|5121637|          13|        277|     500|        106|        197|          0|           0|
|  5121638|5131637|           7|        165|     270|         69|         99|          1|           0|
+---------+-------+------------+-----------+--------+-----------+-----------+-----------+------------+
only showing top 10 rows


'''


##################################
#
# Write to s3 & convert to rdd: 
#  write.mode('append').parquet()
#  write.partitionBy()
#
# References:
#  1). https://spark.apache.org/docs/latest/sql-data-sources-parquet.html#data-source-option
#  2). https://spark.apache.org/docs/latest/api/python/reference/index.html
#  3). https://sparkbyexamples.com/pyspark/pyspark-read-and-write-parquet-file/
#  4). https://towardsdatascience.com/pyspark-and-sparksql-basics-6cb4bf967e53
# 
###################################


# Seems snappy is the only compression type [1], automatic with s3
tgtBucketPath = "s3://band-cloud-audio-validation/1kg-genoDose/chr21-part1-genodose.parquet"
regionalGroupDose.write.parquet(tgtBucketPath, compression = "snappy")
regionalGroupDose_RDD = regionalGroupDose.rdd
regionalGroupDose_RDD.count()

'''

- Writing to parquet on own bucket, 16:20 -> 16:28

[Stage 42:>                                                         (0 + 0) / 2]
22/11/09 16:20:32 WARN MemoryStore: Not enough space to cache broadcast_30 in memory! (computed 1150.8 MiB so far)
22/11/09 16:20:32 WARN BlockManager: Persisting block broadcast_30 to disk instead.
22/11/09 16:21:07 WARN MemoryStore: Not enough space to cache broadcast_30 in memory! (computed 1150.8 MiB so far)


- RDD from query, 16:28 -> 16:38, count took seconds

22/11/09 16:29:29 WARN MemoryStore: Not enough space to cache broadcast_38 in memory! (computed 1150.8 MiB so far)
22/11/09 16:29:29 WARN BlockManager: Persisting block broadcast_38 to disk instead.
22/11/09 16:30:08 WARN MemoryStore: Not enough space to cache broadcast_38 in memory! (computed 1150.8 MiB so far)

'''


#################################################
#################################################
# 
# Submit Steps
# 
#################################################
#################################################

# Copy scripts
aws s3 cp lociDosages-etl-step.py s3://band-cloud-audio-validation/app/genoDoses/
aws s3 cp step-generator.sh s3://band-cloud-audio-validation/app/genoDoses/

# Setup job args
chroms=$(seq 24 | sed 's/^/chr/' | xargs)
dataBucket="s3://aws-roda-hcls-datalake/thousandgenomes_dragen/var_nested"
chrom="chr21"
partKey="chrom=chr21"
dataDir="${dataBucket}/${partKey}"

# Spark submit
jobScript="s3://band-cloud-audio-validation/app/genoDoses/lociDosages-etl-step.py"
data="s3://aws-roda-hcls-datalake/thousandgenomes_dragen/var_nested/chrom=chr21/20210721_220854_00027_s6m5m_030a4aea-0e7f-4970-a614-035403b2f2a1"
jobKey=1
spark-submit \
  --master yarn \
  --deploy-mode cluster \
  ${jobScript} \
    "--data=${data} --jobKey=${jobKey}"
   


# Create & submit steps for jobs
jobDir="1KG-Dosages"
jobScript="s3://band-cloud-audio-validation/app/genoDoses/lociDosages-etl-step.py"
for i in $(aws s3 ls ${dataDir}/ | awk '{ print NR","$NF }')
  do
  jobKey=$(echo $i | cut -d , -f 1)
  db=$(echo $i | cut -d , -f 2)
  bash step-generator.sh "$jobDir" "${chrom}-$jobKey" "$jobScript" "--data=${dataDir}/${db}" "--jobKey=$jobKey"
done 


# Submit: dropped type custom jar + script-runner, left with spark
clusterID="j-3VX7VPSRK5P3I"
aws emr add-steps \
  --region "eu-west-1" \
  --cluster-id "$clusterID" \
  --steps file:///home/ec2-user/1KG-Dosages/chr21-3.json


aws emr list-steps \
  --region "eu-west-1" \
  --cluster-id "$clusterID" \
  --step-ids "s-23JI3DAKA5OCG" "s-17QJGN7LQ8PAI" "s-P8WE5EV8PEE3" \
  --query "Steps[*].Status"


'''

- Steps 1->3

s-1FGXI0FVEYC4N, s-1R54VKKNLOWHV, s-2QK2CN9KJCT37


- Due to how the step is written
"Message": "Exception in thread \"main\" org.apache.spark.SparkException: Failed to get main class in JAR with error 'File file:/mnt/var/lib/hadoop/steps/s-H5TZFVU1JKCE/s3:/band-cloud-audio-validation/app/genoDoses/lociDosages-etl-step.py, s3:/aws-roda-hcls-datalake/thousandgenomes_dragen/var_nested/chrom=chr21/20210721_220854_00027_s6m5m_030a4aea-0e7f-4970-a614-035403b2f2a1 does not exist'.  Please specify one with --class."


- Running as below worked fine
  "script", "--data=XX", "--jobKey=YY" 

'''