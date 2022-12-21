#!/bin/bash


siteData="s3://band-cloud-audio-validation/1kg-genoDose-ETL/csvs/site"
bucket="s3://band-cloud-audio-validation"
count=0
dir=0
dirCounter=0
mkdir -p ~/batch-imports/

cut -d , -f 2 ~/batchesToImport.txt | while read batch
do

    # Set vars
    count=$((${count}+1))
    dirCounter=$((${dirCounter}+1))
    echo -e "bash ~/batch-import-sites.sh ${count} ${bucket} ${batch}" > ~/batch-imports/${count}.sh

    # Manage directory size
    if [ ${dirCounter} -eq 200 ] 
    then
        dir=$((${dir}+1))
        mkdir -p ~/batch-imports/${dir}
        mv ~/batch-imports/*sh ~/batch-imports/${dir}/
        echo -e "Directory count is now: ${dir}"
        dirCounter=0
    fi
done
