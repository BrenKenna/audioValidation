# Setup
mkdir -p tempDir resultsDir
for inp in $( cat text-examples.txt )
    do

    # Fetch
    if [ $(echo ${inp} | grep -c ",") -eq 0 ]
    then
        base=$(basename ${inp} | cut -d \. -f 1)
    else
        base=$(echo $inp | cut -d , -f 2)
        inp=$(echo $inp | cut -d , -f 1)
    fi
    
    # Analyze as mock signal
    if [ $(echo $inp | awk -F "." '{print $NF}' | grep -c "wav") -eq 0 ]
    then
    
        # Generate mock audio signal
        echo -e "\n\nFetching data"
        sleep 10s
        curl -o tempDir/${base}.txt ${inp}
        python run-generator.py -m "tempDir/${base}.txt" -n "${base}" -o "resultsDir"

        # Analyze
        python run-comparator.py -s "resultsDir/${base}-mock-signal.wav" -n "${base}"  -o "resultsDir"

        # Clean up
        rm -f tempDir/${base}.txt results/Dir/${base}*wav
        echo -e "\\n\\n"
    
    # Otherwise analyze normally
    else

        # Analyze
        echo -e "\n\nAnalyzing data"
        python run-comparator.py -s "${inp}" -n "${base}"  -o "resultsDir"
        echo -e "\\n\\n"
    fi
done


# Merge
cat resultsDir/*csv | head -n 1 | cut -d , -f 2- > results-test.csv
cat resultsDir/*csv | grep -v "Track" | cut -d , -f 2- >> results-test.csv


# Pretty print output
echo -e "\\n\\nSummarizing analysis:\\n"
echo -e "Track,tIs Malware"
awk -F "," 'NR > 1 {print $1","$NF}' results-test.csv