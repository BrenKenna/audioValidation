#!/bin/bash

# Set vars
count=$1
siteData=$2
batch=$3

# Manage vars
jobId=$(echo $batch | cut -d \/ -f 4)
chrom=$(echo $batch | cut -d \/ -f 5 | cut -d \= -f 2)
fileId=$(basename ${batch} | cut -d \. -f 1)
data="${siteData}/${batch}"

# Stagger parallel jobs
sleepTime=$(( ( RANDOM % 10 ) + 1 )) 
echo -e "\\n\\nSleeping for ${sleepTime}s so that tasks do not happen the same time"
sleep ${sleepTime}s


# Parse & Put to HDFS
echo -e "\nParsing input data & uploading to HDFS"
hdfs dfs -cat ${data} | sed "s/$/,${fileId},${jobId},${chrom}/g" > batch-${count}_${jobId}-${chrom}.csv
hdfs dfs -put batch-${count}_${jobId}-${chrom}.csv hdfs:///tmp/batch-${count}_${jobId}-${chrom}.csv

varId=$(awk -F "," 'NR == 1 { print $1 }' batch-${count}_${jobId}-${chrom}.csv)
rm -f batch-${count}_${jobId}-${chrom}.csv


# Import
echo -e "\n\nImporting data from: /tmp/batch-${count}_${jobId}-${chrom}.csv"
/usr/bin/time sudo hbase org.apache.hadoop.hbase.mapreduce.ImportTsv \
    -Dimporttsv.separator=',' \
    -Dimporttsv.columns='HBASE_ROW_KEY, f:pos, f:ref, f:alt, f:sampleId, f:GT, f:fileId, f:jobId, f:chrom' \
    "genoDose" \
    /tmp/batch-${count}_${jobId}-${chrom}.csv


# Sanity check
echo -e "\\n\\nSkipping Sanity Check of Import"
# echo -e "get 'genoDose', '${varId}', { COLUMNS => [ 'pos', 'ref', 'alt', 'sampleId', 'GT' ] }" | sudo hbase shell -n


# Clear from hdfs:  147,040
echo -e "\\n\\nClearing imported data from HDFS"
hdfs dfs -rm hdfs:///tmp/batch-${count}_${jobId}-${chrom}.csv