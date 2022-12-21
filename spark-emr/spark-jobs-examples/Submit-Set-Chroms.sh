#!/bin/bash

# Setup
clusterID="j-2HG94C68T9MRC"
jobDir="1KG-Dosages"
jobScript="s3://band-cloud-audio-validation/app/genoDoses/lociDosages-etl-step.py"
dataBucket="s3://aws-roda-hcls-datalake/thousandgenomes_dragen/var_nested"

for chrom in chr{10..15}
do
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

    # Bit high on cores
    for i in $(seq 30)
    do
        aws emr add-steps \
            --region "eu-west-1" \
            --cluster-id "$clusterID" \
            --steps file:///home/hadoop/1KG-Dosages/${chrom}-${i}.json
    done
    sleep 1s
done