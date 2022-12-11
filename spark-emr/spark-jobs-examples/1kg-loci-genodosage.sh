###########################
# 
# Run Dosage Calc
# Initial Data = 60,220
# Exploded = 9,119,966, 131 Partitions
# Regions = 4166, 135 Partitions
# Regional Burden = 3731, Partitions 125
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
''').persist()


# Create regions: Create DF from 1k increments
dataSum = data.describe()
dataSum.show() # Min = 5031637; Max = 46699951; Size = 41,668,314; #-5KB = 4166

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
  Loci.StartLoci, Loci.EndLoci,
  SUM(GenotypeDose.genoSum) as LociDose,
  COUNT(DISTINCT GenotypeDose.variant_id) as VariantCount,
  COUNT(DISTINCT GenotypeDose.id) as SampleCount
FROM GenotypeDose
INNER JOIN Loci 
  ON GenotypeDose.pos >= Loci.StartLoci AND GenotypeDose.pos <= Loci.EndLoci
GROUP BY Loci.StartLoci, Loci.EndLoci
ORDER BY Loci.StartLoci ASC
;
''').persist()
regionalBurden.printSchema()
regionalBurden.show(10)

sample = regionalBurden.sample(
  fraction = 0.01
)
pdf = sample.toPandas()
pdf.info()

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
''').persist()
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


##################

# Write others to csv
sampleLociSum.write.csv("s3://band-cloud-audio-validation/1kg-genoDose/csvs/sampleLoci-sum.csv")
regionalGroupDose.write.csv("s3://band-cloud-audio-validation/1kg-genoDose/csvs/regional-gene-dose.csv")


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
chrom="chr19"
partKey="chrom=chr19"
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
clusterID="j-1ZP4UTFW7C279"
aws emr add-steps \
  --region "eu-west-1" \
  --cluster-id "$clusterID" \
  --steps file:///home/hadoop/1KG-Dosages/chr19-1.json


aws emr list-steps \
  --region "eu-west-1" \
  --cluster-id "$clusterID" \
  --step-ids "s-WIUX78XGMRPP" "s-196NDHU6U5WE7" "s-37XO86B3W9NK4" \
  --query "Steps[*].Status.State"


aws s3 ls s3://band-cloud-audio-validation/1kg-genoDose-ETL/chrom=chr21/

'''

- Steps 1->3

s-1FGXI0FVEYC4N, s-1R54VKKNLOWHV, s-2QK2CN9KJCT37


- Due to how the step is written
"Message": "Exception in thread \"main\" org.apache.spark.SparkException: Failed to get main class in JAR with error 'File file:/mnt/var/lib/hadoop/steps/s-H5TZFVU1JKCE/s3:/band-cloud-audio-validation/app/genoDoses/lociDosages-etl-step.py, s3:/aws-roda-hcls-datalake/thousandgenomes_dragen/var_nested/chrom=chr21/20210721_220854_00027_s6m5m_030a4aea-0e7f-4970-a614-035403b2f2a1 does not exist'.  Please specify one with --class."


- Running as below worked fine, RUNNING > 5mins
  "script", "--data=XX", "--jobKey=YY" 

[
    "COMPLETED", 
    "COMPLETED", 
    "COMPLETED"
]

- Data written

                           PRE 20210721_220854_00027_s6m5m_030a4aea-0e7f-4970-a614-035403b2f2a1/
                           PRE 20210721_220854_00027_s6m5m_07500d55-ef9a-435f-ac51-9930a26c4557/
                           PRE 20210721_220854_00027_s6m5m_08924ac8-37a0-4173-bd2c-4e35df52bb3a/
                           PRE 20210721_220854_00027_s6m5m_fab42b02-6a3b-4c6c-9bf2-2a3da032fa01/
'''

hadoop-yarn-resourcemanager.service


#################################


'''

- Step log

Failing this attempt.Diagnostics: [2022-12-08 13:03:02.233]Container killed on request. Exit code is 137

- Container stdout

Querying Loci Dose
root
 |-- StartLoci: integer (nullable = true)
 |-- EndLoci: integer (nullable = true)
 |-- VariantCount: long (nullable = false)
 |-- SampleCount: long (nullable = false)
 |-- LociDose: long (nullable = true)
 |-- LociHetDose: long (nullable = true)
 |-- LociHomDose: long (nullable = true)
 |-- LociCNVDose: long (nullable = true)
 |-- LociNullDose: long (nullable = true)


#
# java.lang.OutOfMemoryError: Java heap space
# -XX:OnOutOfMemoryError="kill -9 %p"
#   Executing /bin/sh -c "kill -9 1264"...

- Container stderr

22/12/08 13:01:45 INFO BlockManagerInfo: Removed broadcast_2_piece0 on ip-192-168-2-9.eu-west-1.compute.internal:41041 in memory (size: 25.2 KiB, free: 24.5 GiB)
22/12/08 13:01:45 INFO TaskSetManager: Finished task 0.0 in stage 3.0 (TID 5) in 25375 ms on ip-192-168-2-124.eu-west-1.compute.internal (executor 9) (4/4)
22/12/08 13:01:45 INFO YarnClusterScheduler: Removed TaskSet 3.0, whose tasks have all completed, from pool 
22/12/08 13:01:45 INFO DAGScheduler: ResultStage 3 ($anonfun$withThreadLocalCaptured$1 at FutureTask.java:266) finished in 25.387 s
22/12/08 13:01:45 INFO DAGScheduler: Job 2 is finished. Cancelling potential speculative or zombie tasks for this job
22/12/08 13:01:45 INFO YarnClusterScheduler: Killing all running tasks in stage 3: Stage finished

- Other container stdout

Heap
 PSYoungGen      total 691712K, used 538385K [0x00007f0630f00000, 0x00007f0663c80000, 0x00007f0a0d000000)
  eden space 607232K, 88% used [0x00007f0630f00000,0x00007f0651cc45d8,0x00007f0656000000)
  from space 84480K, 0% used [0x00007f065b280000,0x00007f065b280000,0x00007f0660500000)
  to   space 84480K, 0% used [0x00007f0656000000,0x00007f0656000000,0x00007f065b280000)
 ParOldGen       total 2128896K, used 31292K [0x00007efe78c00000, 0x00007efefab00000, 0x00007f0630f00000)
  object space 2128896K, 1% used [0x00007efe78c00000,0x00007efe7aa8f378,0x00007efefab00000)
 Metaspace       used 77211K, capacity 82935K, committed 82944K, reserved 83968K
(END)


- Other container stderr

/12/08 13:02:06 WARN TransportChannelHandler: Exception in connection from ip-192-168-2-146.eu-west-1.compute.internal/192.168.2.146:41237
java.io.IOException: Connection reset by peer
22/12/08 13:02:06 ERROR TransportResponseHandler: Still have 1 requests outstanding when connection from ip-192-168-2-146.eu-west-1.compute.internal/192.168.2.146:
41237 is closed
22/12/08 13:02:06 WARN Executor: Issue communicating with driver in heartbeater
org.apache.spark.SparkException: Exception thrown in awaitResult: 
22/12/08 13:02:06 ERROR YarnCoarseGrainedExecutorBackend: Executor self-exiting due to : Driver ip-192-168-2-146.eu-west-1.compute.internal:41237 disassociated! Sh
utting down.
22/12/08 13:02:06 INFO YarnCoarseGrainedExecutorBackend: Driver from ip-192-168-2-146.eu-west-1.compute.internal:41237 disconnected during shutdown
22/12/08 13:02:06 INFO MemoryStore: MemoryStore cleared
22/12/08 13:02:06 INFO BlockManager: BlockManager stopped
22/12/08 13:02:06 INFO ShutdownHookManager: Shutdown hook called

'''



# Create & submit steps for jobs
clusterID="j-SJZ0QUWQ6WLJ"
jobDir="1KG-Dosages"
jobScript="s3://band-cloud-audio-validation/app/genoDoses/lociDosages-etl-step.py"
chroms=$(seq 24 | sed 's/^/chr/' | xargs)
dataBucket="s3://aws-roda-hcls-datalake/thousandgenomes_dragen/var_nested"
chrom="chr16"
partKey="chrom=${chrom}"
dataDir="${dataBucket}/${partKey}"

for i in $(aws s3 ls ${dataDir}/ | awk '{ print NR","$NF }')
  do
  jobKey=$(echo $i | cut -d , -f 1)
  db=$(echo $i | cut -d , -f 2)
  bash step-generator.sh "$jobDir" "${chrom}-$jobKey" "$jobScript" \
    "--data=${dataDir}/${db}" "--jobKey=$jobKey" \
    "10g" "2" "5g" "2" "30"
done 


# Bit high on cores & mem <= for what is involved
for i in $(seq 30)
  do
  aws emr add-steps \
    --region "eu-west-1" \
    --cluster-id "$clusterID" \
    --steps file:///home/hadoop/1KG-Dosages/${chrom}-${i}.json
done

aws emr list-steps \
  --region "eu-west-1" \
  --cluster-id "$clusterID" \
  --step-ids "s-1P1EV00JFLQ3Z" "s-2KIMKJFRBWVR9" \
  --query "Steps[*].Status"


'''

{
    "StepIds": [
        "s-3IC1YP23B5SJ5"
    ]
}


22/12/08 13:39:05 WARN BlockManagerMasterEndpoint: Error trying to remove broadcast 15 from block manager BlockManagerId(76, ip-192-168-2-14.eu-we
st-1.compute.internal, 38987, None)
java.io.IOException: Failed to send RPC RPC 5412256041603634174 to /192.168.2.14:33462: io.netty.channel.StacklessClosedChannelException

Caused by: io.netty.channel.StacklessClosedChannelException
        at io.netty.channel.AbstractChannel$AbstractUnsafe.write(Object, ChannelPromise)(Unknown Source)
22/12/08 13:39:05 WARN NettyRpcEnv: Ignored failure: java.io.IOException: Failed to send RPC RPC 5477778275273416466 to /192.168.2.124:57774: io.n
etty.channel.StacklessClosedChannelException


Container: container_1670502789040_0002_01_000001 on ip-192-168-2-245.eu-west-1.compute.internal_8041
LogAggregationType: AGGREGATED

End of LogType:stdout
***********************************************************************

Container: container_1670502789040_0002_01_000195 on ip-192-168-2-245.eu-west-1.compute.internal_8041
LogAggregationType: AGGREGATED
'''


# Difference in enabling fair-sharing
cd /etc/hadoop/conf
cp yarn-site.xml backup.yarn-site.xml
systemctl status hadoop-yarn-resourcemanager
systemctl stop hadoop-yarn-resourcemanager
systemctl start hadoop-yarn-resourcemanager


cd /etc/spark/conf


'''

- Minimal config
<property>
  <name>yarn.resourcemanager.scheduler.class</name>
  <value>org.apache.hadoop.yarn.server.resourcemanager.scheduler.fair.FairScheduler</value>
</property>


- Before stop

● hadoop-yarn-resourcemanager.service - Hadoop resourcemanager
   Loaded: loaded (/etc/systemd/system/hadoop-yarn-resourcemanager.service; enabled; vendor preset: disabled)
   Active: active (running) since Thu 2022-12-08 12:33:08 UTC; 6h ago
 Main PID: 32507 (java)
    Tasks: 356
   Memory: 1.8G
   CGroup: /system.slice/hadoop-yarn-resourcemanager.service
           └─32507 /etc/alternatives/jre/bin/java -Dproc_resourcemanager -Djava.net.preferIPv4Stack=true -server -XX:+ExitOnOutOfMemoryError -XX:+ExitOnOutOfMem...


- Stopped
● hadoop-yarn-resourcemanager.service - Hadoop resourcemanager
   Loaded: loaded (/etc/systemd/system/hadoop-yarn-resourcemanager.service; enabled; vendor preset: disabled)
   Active: failed (Result: exit-code) since Thu 2022-12-08 18:38:10 UTC; 3s ago
 Main PID: 32507 (code=exited, status=143)


- Started

● hadoop-yarn-resourcemanager.service - Hadoop resourcemanager
   Loaded: loaded (/etc/systemd/system/hadoop-yarn-resourcemanager.service; enabled; vendor preset: disabled)
   Active: active (running) since Thu 2022-12-08 18:39:00 UTC; 44s ago
  Process: 38228 ExecStart=/etc/init.d/hadoop-yarn-resourcemanager start (code=exited, status=0/SUCCESS)
 Main PID: 38415 (java)
    Tasks: 340
   Memory: 651.0M
   CGroup: /system.slice/hadoop-yarn-resourcemanager.service
           └─38415 /etc/alternatives/jre/bin/java -Dproc_resourcemanager -Djava.net.preferIPv4Stack=true -server -XX:+ExitOnOutOfMemoryError -XX:+ExitOnOutOfMem...


- Memory & #Executors:
    => 2.4x10^12 dimensional space every ~35 mins
    => Each of the ~12 steps ~80M rows, and ~3k nested columns.
    => Cluster has ~2TB Mem, ~500 vCPU.
    => Throughout the process all ~9/12 (75%) steps were utilizing ~10% of cluster.
    => 2 jobs finished way sooner than others (~17%)
    => No run offs

- Speculation did not offer much change:
    => Introduced two types of run offs, maybe value is a little low?
    => Occasionally 1 job would snatch all resources, but would finish quickly (8.3%).
    => When this happens 2 jobs were delayed way later than others (~17%)

- Reorganizing app code a little would be better than above:
    => Checkpoints, have HDFS storage use it better

- Broad point about approach still a common nice one:
    => 2TB cluster packs quite a punch.
    => N steps (chunks of genome) dealing out M windows (loci within dataset).
    => Each step could iteratively analyze different categories/classes of data from the M windows.


- Caching did indeed improve wall times
    => Results object is summarized, 10 records checked and written to S3.
    => Noticed that the site-sample exploded table only has one partition, and not sorted
        - Observed writing csv (630 MB)
        - Sorting by position ascendingly & repartitioning to 200 tables
            => This halved the time!!!!!!!!
        - Loci burden has 200 partitions, and is ~340 KB

- Summary:
  a). App code updates offer wall time updates
  b). Supplied config helped improving the distribution of load across apps.
  c). Increase the number of concurrent that could run

  => Replicate "b-c" given knowledge of a
      - Test was with chr18, took 50% less time
      - Without numExecutors, memory + cores = load was not split evenly
      - Reintroducing even distribution (7.1% across 13 steps, 4.7% for "last")
      - Rest of job is < 30s... lol
      - Testing chr17:
          => ~40minx no cahce
          => ~20mins w/cache.
          => ~10 mins ~ w/ cache, sort & repartition
      - Sanity checking again with chr16:
          => ~10 mins ~ w/ cache, sort & repartition
      - With all 30 partitions:
          => % of cluster per app changes frequently
          => ~10 are usually less <1% (comes back to app config values)
          => ~5 split across 3-6%
          => 50% done after ~10 mins ~ w/ cache, sort & repartition
          => >16:56 ; 11 done ~10 mins ~ w/ cache, sort & repartition
          => Whole chromosome would be done same time, in step limit was 15
              => Come back to load distribution & walltime (~3% per app).
'''

