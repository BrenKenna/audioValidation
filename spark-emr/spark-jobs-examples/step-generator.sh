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
driverMemory=${6:-10g}
driverCores=${7:-1}
executorMemory=${8:-5g}
executorCores=${9:-1}
maxExecutors=${10:-infinity}
speculationMinTime=${11:-""}

if [ ! -z $speculationMinTime ]
then
    speculation="\"--conf\", \"spark.speculation=True\""
    speculation="${speculation},\"--conf\", \"spark.speculation.minTaskRuntime=${speculationMinTime}\","
else
    speculation=""
fi

# conf=$5 # For laterz

# Write out json
# spark.speculation = true, spark.speculation.minTaskRuntime = 8min
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
            
            \"--conf\", \"spark.driver.memory=${driverMemory}\",
            \"--conf\", \"spark.driver.cores=${driverCores}\",

            \"--conf\", \"spark.executor.memory=${executorMemory}\",
            \"--conf\", \"spark.executor.cores=${executorCores}\",

            \"--conf\", \"spark.dynamicAllocation.maxExecutors=${maxExecutors}\",
            ${speculation}
            \"${jobScript}\", \"${scriptDB}\", \"$scriptJobKey\"
        ]

    }
]
""" > $jobDir/$jobName.json