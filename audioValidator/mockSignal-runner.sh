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
    curl -o tempDir/${base}.txt ${inp}

    # Generate mock audio signal
    python run-generator.py -m "tempDir/${base}.txt" -n "${base}" -o "resultsDir"

    # Analyze
    python run-comparator.py -s "resultsDir/${base}-mock-signal.wav" -n "${base}"  -o "resultsDir"

    # Clean up
    rm -f tempDir/${base}.txt results/Dir/${base}*wav
done