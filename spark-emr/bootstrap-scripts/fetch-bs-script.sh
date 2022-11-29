#!/bin/bash

# Fetch & run package install script as background job
sudo aws s3 cp s3://band-cloud-audio-validation/cluster/package-installer.sh ./
sudo mkdir /tmp/custom-boostrap-test
sudo chmod +x package-installer.sh
nohup ./package-installer.sh /usr/share/aws/emr/emrfs/lib &>> /dev/null &