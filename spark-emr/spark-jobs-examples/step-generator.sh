#!/bin/bash

####################################
####################################
# 
# Create step with simple arg
# 
####################################
####################################

# Args
jobDir=$1
jobName=$2
jobScript=$3
scriptDB=$4
scriptJobKey=$5
# conf=$5 # For laterz

# Write out json
mkdir -p $jobDir
echo -e """
[
    {
        \"Name\": \"$jobName\",
        \"ActionOnFailure\": \"CONTINUE\",
        \"Type\": \"CUSTOM_JAR\",
        \"Jar\": \"command-runner.jar\",
        \"Args\": [
            \"spark-submit\",
            \"--deploy-mode\", \"cluster\",
            \"--master\", \"yarn\",
            \"--conf\", \"spark.yarn.submit.waitAppCompletion=true\",
            \"${jobScript}\", \"${scriptDB}\", \"$scriptJobKey\"
        ]

    }
]
""" > $jobDir/$jobName.json