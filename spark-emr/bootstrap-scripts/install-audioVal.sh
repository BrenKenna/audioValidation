#!/bin/bash

# Check directories
echo -e "\\nChecking Directories Customer Uses\\n"
if [ ! -d /usr/share/aws/emr/emrfs/lib ]
then
    echo -e "Nope = /usr/share/aws/emr/emrfs/lib"
else
    ls -lha /usr/share/aws/emr/emrfs/lib
fi

if [ ! -d /usr/share/aws/emr/emrfs/ ]
then
    echo -e "Nope = /usr/share/aws/emr/emrfs/"
else
    ls -lha /usr/share/aws/emr/emrfs/
fi

if [ ! -d /usr/share/aws/emr/ ]
then
    echo -e "Nope = /usr/share/aws/emr/"
else
    ls -lha /usr/share/aws/emr/
fi

if [ ! -d /usr/share/aws/ ]
then
    echo -e "Nope = /usr/share/aws/"
else
    ls -lha /usr/share/aws/
fi



# Install package
sudo aws s3 cp s3://band-cloud-audio-validation/cluster/audioVal-Test.py /usr/share/aws/emr/emrfs/lib