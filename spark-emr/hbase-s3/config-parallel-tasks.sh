#!/bin/bash

# Bundle into a way to run parallel jobs more easily
mkdir ~/parallel-jobs
tree -fish batch-imports/ | \
    awk ' $NF ~ /sh/ { print "bash ~/"$NF" 2>&1 > ~/"$NF".log"}'| \
    split -l 200 - ~/parallel-jobs/task-

counter=0
ls ~/parallel-jobs/ | while read line
do
    counter=$((${counter}+1))
    mv ~/parallel-jobs/${line} ~/parallel-jobs/task-${counter}.sh
done
