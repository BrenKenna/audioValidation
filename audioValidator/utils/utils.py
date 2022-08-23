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


# Audio validator modules
from generator import generator
from results import results
from comparator import comparator


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
def classifyAudioSignal(track, signal):
    
    # Analyze track
    trackAna = analyzeAudio(track, signal)
    audioVal = fetchModel()

    # Run classification    
    print('\nApplying classifier')
    output = trackAna.getResultsAsRow()
    audioVal.compareRow(output, assignToDF = True)
    
    # Return results
    return output



# Generate and classify signal
def classifyMockSignal(name, mockData):
    
    # Generate audio signal
    generateMockAudio(name, mockData)
    
    # Classify audio signal
    output = classifyAudioSignal(name, str(name + "-mock-signal.wav"))
    
    # Return results
    return output