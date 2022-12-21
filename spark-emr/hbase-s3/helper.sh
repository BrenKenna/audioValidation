############################################
# 
# Trigger Region Splitting
#   => Object size <10KB
#   => 2500000000000 / 2500000000 = 1000
#
# ssh -v -i <KEY> -ND <PORT> <USER>@<IP Address>
# 
#
# References:
# https://bigdataprogrammers.com/import-csv-data-into-hbase/
# https://diogoalexandrefranco.github.io/interacting-with-hbase-from-pyspark/#spark-hbase-connector
# 
############################################


# 
clusterID="j-2HG94C68T9MRC"
jobDir="1KG-Dosages"
jobScript="s3://band-cloud-audio-validation/app/genoDoses/lociDosages-etl-step.py"
chroms=$(seq 24 | sed 's/^/chr/' | xargs)
dataBucket="s3://aws-roda-hcls-datalake/thousandgenomes_dragen/var_nested"
chrom="chr21"
partKey="chrom=${chrom}"
dataDir="${dataBucket}/${partKey}"

for chrom in chr{10.15}
    for i in $(aws s3 ls ${dataDir}/ | awk '{ print NR","$NF }')
    do
        jobKey=$(echo $i | cut -d , -f 1)
        db=$(echo $i | cut -d , -f 2)
        bash step-generator.sh "$jobDir" "${chrom}-$jobKey" "$jobScript" \
            "--data=${dataDir}/${db}" "--jobKey=$jobKey" \
            "10g" "2" "5g" "2" "30"
    done

    # Bit high on cores
    for i in $(seq 30)
    do
        aws emr add-steps \
            --region "eu-west-1" \
            --cluster-id "$clusterID" \
            --steps file:///home/hadoop/1KG-Dosages/${chrom}-${i}.json
    done
done 


# Bit high on cores
for i in $(seq 30)
  do
  aws emr add-steps \
    --region "eu-west-1" \
    --cluster-id "$clusterID" \
    --steps file:///home/hadoop/1KG-Dosages/${chrom}-${i}.json
done


############################################################


# Spinup cluster: 2-106
bash spinup-cluster.sh


'''

{
    "ClusterId": "j-20TBP3E0N8WXR", 
    "ClusterArn": "arn:aws:elasticmapreduce:eu-west-1:986224559876:cluster/j-20TBP3E0N8WXR"
}

'''

# Create table in genoDose
#  fileName,chrom,varId,ref,alt,sampleId,geno
echo -e "
    create_namespace 'kgData'
    create 'kgData:genoDose' 'genoDose:fileName',
        'genoDose:chrom', 
        'genoDose:varId',
        'genoDose:ref',
        'genoDose:alt',
        'genoDose:sampleId',
        'genoDose:GT'
" | hbase shell -n 

#
# Previously encountered 'master initilization' error
#   => First happened in a subnet with two clusters (tried 1 and included zookeeper).
#   => Then edited '/etc/hosts' & restarted hbase service on instances
#   => On a new cluster added a rule to allow all TCP inbound ports from VPC
#       => Creating namespaces worked fine after :) 
hbase shell

`
status
list
create_namespace 'kgData'
create 'genoDose', 'fileName', 'chrom',  'varId', 'ref', 'alt', 'sampleId', 'GT'

`

hive 

"""
set hbase.zookeeper.quorum=ip-192-168-2-80.eu-west-1.compute.internal;
create external table testingTable (key string, value string)
     stored by 'org.apache.hadoop.hive.hbase.HBaseStorageHandler'
      with serdeproperties ('hbase.columns.mapping' = ':key,f1:col1')
      tblproperties ('hbase.table.name' = 'testingTable');

select count(key) from testingTable ;
"""


# Requires data on HDFS
# May need to add header
hbase org.apache.hadoop.hbase.mapreduce.ImportTsv \
    -Dimporttsv.separator=','
    -Dimporttsv.columns='HBASE_ROW_KEY,fileName, chrom, varId, ref, alt, sampleId, GT' \
    emp_data \
    /user/bdp/hbase/data/emp_data.csv


##################################
##################################
#
# Data on S3
#
##################################
##################################


# Install parallel
sudo amazon-linux-extras install -y epel
sudo yum install -y parallel


# Create pre-split table
sudo hbase shell

`
disable 'genoDose'
drop 'genoDose'
`

date; sudo hbase org.apache.hadoop.hbase.util.RegionSplitter \
    genoDose \
    HexStringSplit \
    -c 120 \
    -f varId:pos:ref:alt:sampleId:GT:fileId:jobId:chrom
date

# Rack em & stack em: N = 49200
siteData="s3://band-cloud-audio-validation/1kg-genoDose-ETL/csvs/site/"
aws s3 ls --recursive ${siteData} | awk '$NF ~ /csv$/ { print "'${siteData}',"$NF}' > batchesToImport.txt
wc -l batchesToImport.txt


# Set up the bulk-import tasks:  N = 246 batches of 200 tasks
bash setup-batch-imports.sh


# Bundle into a way to run parallel jobs more easily
#  Randomly shuffle both
mkdir ~/parallel-jobs
counter=0
tree -fish batch-imports/ | sort -R | \
    awk ' $NF ~ /sh/ { print "bash ~/"$NF" 2>&1 > ~/"$NF".log"}'| \
    split -l 200 - ~/parallel-jobs/task-

ls ~/parallel-jobs/ | sort -R | while read line
do
    counter=$((${counter}+1))
    mv ~/parallel-jobs/${line} ~/parallel-jobs/task-${counter}.sh
done


# Run N task scripts from parallel-set
# 33385
nohup $(parallel -kj 10 < ~/parallel-jobs/task-1.sh) 2>&1 > ~/parallel-jobs/task-1.log &
sleep 10s
nohup $(parallel -kj 10 < ~/parallel-jobs/task-2.sh) 2>&1 > ~/parallel-jobs/task-2.log &
sleep 10s
nohup $(parallel -kj 10 < ~/parallel-jobs/task-3.sh) 2>&1 > ~/parallel-jobs/task-3.log &
sleep 10s
nohup $(parallel -kj 10 < ~/parallel-jobs/task-4.sh) 2>&1 > ~/parallel-jobs/task-4.log &
sleep 10s
nohup $(parallel -kj 10 < ~/parallel-jobs/task-5.sh) 2>&1 > ~/parallel-jobs/task-5.log &
sleep 10s
nohup $(parallel -kj 10 < ~/parallel-jobs/task-6.sh) 2>&1 > ~/parallel-jobs/task-6.log &
sleep 10s
nohup $(parallel -kj 10 < ~/parallel-jobs/task-7.sh) 2>&1 > ~/parallel-jobs/task-7.log &
sleep 10s
nohup $(parallel -kj 10 < ~/parallel-jobs/task-8.sh) 2>&1 > ~/parallel-jobs/task-8.log &
sleep 10s
nohup $(parallel -kj 10 < ~/parallel-jobs/task-9.sh) 2>&1 > ~/parallel-jobs/task-9.log &
sleep 10s
nohup $(parallel -kj 10 < ~/parallel-jobs/task-10.sh) 2>&1 > ~/parallel-jobs/task-10.log &
sleep 30s
nohup $(parallel -kj 10 < ~/parallel-jobs/task-11.sh) 2>&1 > ~/parallel-jobs/task-11.log &
sleep 10s
nohup $(parallel -kj 10 < ~/parallel-jobs/task-12.sh) 2>&1 > ~/parallel-jobs/task-12.log &
sleep 10s
nohup $(parallel -kj 10 < ~/parallel-jobs/task-13.sh) 2>&1 > ~/parallel-jobs/task-13.log &
sleep 10s
nohup $(parallel -kj 10 < ~/parallel-jobs/task-14.sh) 2>&1 > ~/parallel-jobs/task-14.log &
sleep 10s
nohup $(parallel -kj 10 < ~/parallel-jobs/task-15.sh) 2>&1 > ~/parallel-jobs/task-15.log &
sleep 10s
nohup $(parallel -kj 10 < ~/parallel-jobs/task-16.sh) 2>&1 > ~/parallel-jobs/task-16.log &
sleep 10s
nohup $(parallel -kj 10 < ~/parallel-jobs/task-17.sh) 2>&1 > ~/parallel-jobs/task-17.log &
sleep 10s
nohup $(parallel -kj 10 < ~/parallel-jobs/task-18.sh) 2>&1 > ~/parallel-jobs/task-18.log &
sleep 10s
nohup $(parallel -kj 10 < ~/parallel-jobs/task-19.sh) 2>&1 > ~/parallel-jobs/task-19.log &
sleep 30s
nohup $(parallel -kj 10 < ~/parallel-jobs/task-20.sh) 2>&1 > ~/parallel-jobs/task-20.log &
sleep 10s
nohup $(parallel -kj 10 < ~/parallel-jobs/task-21.sh) 2>&1 > ~/parallel-jobs/task-21.log &
sleep 10s
nohup $(parallel -kj 10 < ~/parallel-jobs/task-22.sh) 2>&1 > ~/parallel-jobs/task-22.log &
sleep 10s
nohup $(parallel -kj 10 < ~/parallel-jobs/task-23.sh) 2>&1 > ~/parallel-jobs/task-23.log &




sleep 10s
nohup $(parallel -kj 10 < ~/parallel-jobs/task-24.sh) 2>&1 > ~/parallel-jobs/task-24.log &
sleep 10s
nohup $(parallel -kj 10 < ~/parallel-jobs/task-25.sh) 2>&1 > ~/parallel-jobs/task-25.log &
sleep 10s
nohup $(parallel -kj 10 < ~/parallel-jobs/task-26.sh) 2>&1 > ~/parallel-jobs/task-26.log &
sleep 10s
nohup $(parallel -kj 10 < ~/parallel-jobs/task-27.sh) 2>&1 > ~/parallel-jobs/task-27.log &
sleep 10s
nohup $(parallel -kj 10 < ~/parallel-jobs/task-28.sh) 2>&1 > ~/parallel-jobs/task-28.log &
sleep 10s
nohup $(parallel -kj 10 < ~/parallel-jobs/task-29.sh) 2>&1 > ~/parallel-jobs/task-29.log &
sleep 10s
nohup $(parallel -kj 10 < ~/parallel-jobs/task-30.sh) 2>&1 > ~/parallel-jobs/task-30.log &




# Kill
tree -fish batch-imports/ | awk ' $NF ~ /log/ { print $NF }' | while read line
do
    batchPID=$(lsof ${line} | awk '{print $2}' | xargs)
    if [ ! -z $( echo ${batchPID} | awk '{print $1}' ) ]
    then
        kill ${batchPID}
    fi
done



############################
# 
# Log Diving
# 
############################

aws s3 sync \
    s3://aws157-logs-prod-us-east-2/j-1ZAVI5ZXWH370/node/ . \
    --exclude '*' \
    --include 'applications/hbase/hbase*'

aws s3 ls --recursive s3://myClusters/myCluster/node/ | \
    awk ' $NF ~ /applications\/hbase\/hbase/ {print "s3://aws157-logs-prod-us-east-2/"$NF}' | \
    while read line; do DIR=$(dirname ${line} | cut -d \/ -f 4-); mkdir -p ${DIR}; aws s3 cp ${line} ${DIR}/ ; done



############################################################


# 
pyspark --master yarn


# Load modules
import os, sys, boto3, shutil
import json
import matplotlib.pyplot as plt
import pandas as pd

from pyspark.sql import SparkSession
spark = SparkSession.builder.getOrCreate()
sc = spark.sparkContext


# Set numba cache dir before librosa import
os.environ["NUMBA_CACHE_DIR"] = "/tmp/NUMBA_CACHE_DIR/"
from audioValidator.results import results


# Fetch track
bucket = "band-cloud-audio-validation"
prefix = "real/"
s3_client = boto3.client('s3')
trackPath = "s3://band-cloud-audio-validation/real/Grand-Gathas-of-Baal-Sin.wav"
track = "Grand-Gathas-of-Baal-Sin.wav"
outPath = "/home/hadoop/Grand-Gathas-of-Baal-Sin.wav"
s3Client.download_file(bucket, track, outPath)


# Load track
audioHandler = results.AudioValResult()
audioData = results.loadTrack(outPath)

# Read hbase table spark
df = sqlContext.read.format('org.apache.hadoop.hbase.spark') \
    .option('hbase.table','books') \
    .option('hbase.columns.mapping', \
            'title STRING :key, \
            author STRING info:author, \
            year STRING info:year, \
            views STRING analytics:views') \
    .option('hbase.use.hbase.context', False) \
    .option('hbase.config.resources', 'file:///etc/hbase/conf/hbase-site.xml') \
    .option('hbase-push.down.column.filter', False) \
    .load()

df.show()


# Read audio tracks from s3




# Load into DB as: { 'Track': "", "AudioSignal": [] }





############
#
# ERROR: KeeperErrorCode = NoNode for /hbase/master
#
############


# Not running?
systemctl --type=service | grep "hbase"
systemctl status hbase-master
ls /var/log/hbase/ | wc -l

'''
  hbase-master.service                   loaded active running HBase master daemon
  hbase-rest.service                     loaded active running HBase rest daemon
  hbase-thrift.service                   loaded active running HBase thrift daemon

● hbase-master.service - HBase master daemon
   Loaded: loaded (/etc/systemd/system/hbase-master.service; enabled; vendor preset: disabled)
   Active: active (running) since Fri 2022-12-16 13:05:08 UTC; 6s ago
  Process: 28332 ExecStart=/usr/lib/hbase/bin/hbase-daemon.sh start master (code=exited, status=0/SUCCESS)
 Main PID: 28395 (java)
    Tasks: 83
   Memory: 341.4M
   CGroup: /system.slice/hbase-master.service
           ├─28381 bash /usr/lib/hbase/bin/hbase-daemon.sh --config /etc/hbase/conf foreground_start master
           └─28395 /etc/alternatives/jre/bin/java -Dproc_master -XX:OnOutOfMemoryError=kill -9 %p -Xmx1024m -XX:+UseConcMarkSweepGC -XX:+UseParNewGC -XX:CMSIniti...

12
'''



for node in $(echo -e "192.168.2.113 192.168.2.169 192.168.2.133 192.168.2.124 192.168.2.168 192.168.2.39 192.168.2.34 192.168.2.60")
    do
    ssh -i ~/.ssh/emrKey.pem hadoop@${node} "sudo systemctl stop hbase-regionserver; sleep 5s; sudo systemctl start hbase-regionserver; sleep 2s; sudo systemctl status hbase-regionserver"
done

