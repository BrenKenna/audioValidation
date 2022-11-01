# -*- coding: utf-8 -*-
"""
Created on Tue Aug 23 11:19:25 2022

@author: kenna
"""

# Import required modules
import os, sys, argparse
import json
import matplotlib.pyplot as plt
import pandas as pd
import boto3
import shutil
s3Client = boto3.client('s3')


# Audio validator modules
from audioValidator.generator import generator
from audioValidator.results import results
from audioValidator.comparator import comparator


# Generate mock audio signal
def generateMockAudio(name, mockData):
    
    # Load signal
    mockSignal = generator.AudioValGenerator(name, mockData)
    mockSignal.generateSignal()
    
    # Export to wav: (1102262, 11022)
    mockSignal.exportWav(str(name + "-mock-signal.wav"))
    print(
        "\nSignal generated for:\t" + str(name) + "\n" +
        "Generated wave:\t" + str(mockSignal.audioSignal.shape[0])
        + "\nSampling Rate:\t" + str(mockSignal.sampleRate)
    + "\n")



# Return results object from track & trackame
def analyzeAudio(track, signal):
    
    # Analyze input track
    print('\nReading audio signal & measuring tempo')
    trackAna = results.AudioValResult(track, signal)
    trackAna.setTempo()
    
    # Generate chromagram
    print('\nSeparating haromic from percussive signal for chromagram analysis')
    trackAna.percusHarmonSep()
    trackAna.generateChromagram()
    
    # Set results
    print('\nAnalyzing results and summarizing for classifier')
    trackAna.analyzeChroma()
    trackAna.setResults()
    
    # Return results
    return trackAna



# Write results to file
def resultsToJson(trackAna, outpath):
    outJson = str(trackAna.trackName + "-results.json")
    with open(outJson, 'w') as outfile:
        json.dump(trackAna.results, outfile)
    outfile.close()


# Get audio
def getAudio(Bucket = None, Prefix = None, Key = None, Download = True, OutPath = None):

    if Download == True and OutPath != None:
        print(OutPath)
        os.makedirs(os.path.dirname(OutPath), exist_ok = True)
        s3Client.download_file(Bucket, Key, OutPath)
        output = os.path.exists(OutPath)

    else:
        output = s3Client.get_object(Bucket = Bucket, Key = Key)

    # Download path
    return output


# Fetch model
def fetchModel():
    
    # Instantiate & load model
    print('\n\nFetching training model')
    audioVal = comparator.AudioValComparator()
    audioVal.loadTrainingSet()
    audioVal.setState()
    
    # Return object
    return audioVal



# Write out classification
def writeClassification(dataframe, outprefix = None, outType = True):
    
    # Write to Json
    if outType:
        outJson = str(outprefix + "-classification.json")
        with open(outJson, 'w') as outfile:
            json.dump(dataframe.to_json(orient = 'index'), outfile)
        outfile.close()

    # Otherwise CSV
    else:
        outCSV = str(outprefix + "-classification.csv")
        dataframe.to_csv(outCSV)



# Classifiy audio signal
def classifyAudioSignal(track, signal, outDict = True):
    
    # Analyze track
    trackAna = analyzeAudio(track, signal)
    audioVal = fetchModel()

    # Run classification    
    print('\nApplying classifier')
    output = trackAna.getResultsAsRow()
    audioVal.compareRow(output, assignToDF = True)
    
    # Return results as dict
    if outDict:
        return json.loads(output.to_json(orient = 'index'))['0']

    # Otherwise json string
    else:
        return output.to_json(orient = 'index')


# Classify from tuple
def classifyAudioSignal_fromTuple(item):
    
    # Handle optional arg
    if len(item) > 3:
        print("Error, malformed input")
        return -1
    
    elif len(item) == 3:
        return classifyAudioSignal(item[0], item[1], outDict = item[2])
    
    else:
        return classifyAudioSignal(item[0], item[1]) 


# Generate and classify signal
def classifyMockSignal(name, mockData):
    
    # Generate audio signal
    generateMockAudio(name, mockData)
    
    # Classify audio signal
    output = classifyAudioSignal(name, str(name + "-mock-signal.wav"))
    
    # Return results
    return output


# Classify from tuple
def classifyMockSignal_fromTuple(item):
    
    # Handle optional arg
    if len(item) > 2:
        print("Error, malformed input")
        return -1

    else:
        return classifyMockSignal(item[0], item[1])


# Download and classify
def fetchAndClassify(bucket, key, outDir):

    # Setup record
    track = key.split('/')[-1]
    trackName = track.replace('wav', '')
    trackPath = str(outDir + "/" + track)

    # Fetch track
    getAudio(Bucket = bucket, Key = key, OutPath = trackPath)

    # Run analyzer
    item = (trackName, trackPath)
    classifyAudioSignal_fromTuple(item)

    # Remove file and tmp path
    os.remove(trackPath)
    shutil.rmtree(os.path.dirname(outDir))


# Run fetch and classify
def runFetchAndClassify(item):

    # Handle optional arg
    if len(item) > 3:
        print("Error, malformed input")
        return -1
    
    # Fetch and run
    fetchAndClassify(item[0], item[1], item[2])