#!/bin/bash

DIR=$1
date
while [ ! -d $DIR ]
    do
    echo -e "Waiting for Target Directory\\n"
    sleep 1m
done

# Fetch target script
date
sudo aws s3 cp s3://band-cloud-audio-validation/cluster/audioVal-Test.py ${DIR}
ls -lh ${DIR}