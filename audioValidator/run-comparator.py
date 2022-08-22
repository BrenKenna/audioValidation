# -*- coding: utf-8 -*-
"""
Created on Mon Aug 22 12:44:45 2022

@author: kenna
"""

# Import required modules
import os, sys, argparse
import json
import matplotlib.pyplot as plt
import pandas as pd



###################################
###################################
#
# Run comparator
#
###################################
###################################


# Help page
parser = argparse.ArgumentParser(description = "Use summary statistics from audio finger printing to decern text or audio.", formatter_class = argparse.RawTextHelpFormatter)


# Arguments
parser.add_argument("-s", "--signal", action = 'store', type = str, help = "Input WAV signal\n")
parser.add_argument("-n", "--name", action = 'store', type = str, help = "Identifier for signal\n")
args = parser.parse_args()


# Exit if key argument are not supplied
if args.signal == None or args.name == None:

	# Exit if no table is provided
	sys.stdout.write('\n\nExiting, key variables not provided. Required arguments are input audio signal as WAV and an indentifier for this signal')
	parser.print_help()
	sys.exit()


# Otherwise proceed
else:
	signal = args.signal
	name = args.name
	sys.stdout.write('\n\nProceeding with ' + signal + '\n')


# Verify file exists
# !os.path.exists(signal) -> giving error?
if os.path.exists(signal) == False:
    sys.stdout.write('Error, input signal not found "' + signal + '"')
    sys.exit()



###################################
###################################
#
# Run comparator
#
###################################
###################################


# Audio validator modules
from generator import generator
from results import results
from comparator import comparator


#######################
#
# Analyze track
#
#######################


# Analyze input track
sys.stdout.write('\nReading audio signal & measuring tempo')
trackAna = results.AudioValResult(name, signal)
trackAna.setTempo()


# Generate chromagram
sys.stdout.write('\nSeparating haromic from percussive signal for chromagram analysis')
trackAna.percusHarmonSep()
trackAna.generateChromagram()


# Set results
sys.stdout.write('\nAnalyzing results and summarizing for classifier')
trackAna.analyzeChroma()
trackAna.setResults()


#######################
#
# Classify track
#
#######################


# Instantiate & load model
sys.stdout.write('\n\nFetching training model')
audioVal = comparator.AudioValComparator()
audioVal.loadTrainingSet()
audioVal.setState()


# For testing all methods
sys.stdout.write('\nApplying classifier')
output = trackAna.getResultsAsRow()
audioVal.compareRow(output, assignToDF = True)


# Handle results
sys.stdout.write('\n\nHandling results')
print(str(name) + " label = " + str(output["Label"][0]) )


# Export to csv
outCSV = str(name + "-classification.csv")
output.to_csv(outCSV)


# Write to JSON
outJson = str(name + "-classification.json")
with open(outJson, 'w') as outfile:
    json.dump(output.to_json(orient = 'index'), outfile)
outfile.close()