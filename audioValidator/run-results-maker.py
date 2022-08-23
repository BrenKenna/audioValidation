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
# Run results generator
#
###################################
###################################


# Help page
parser = argparse.ArgumentParser(description = "Output results for classification", formatter_class = argparse.RawTextHelpFormatter)


# Arguments
parser.add_argument("-s", "--signal", action = 'store', type = str, help = "Input WAV signal\n")
parser.add_argument("-n", "--name", action = 'store', type = str, help = "Identifier for signal\n")
args = parser.parse_args()


# Exit if key argument are not supplied
if args.signal == None or args.name == None:

	# Exit if no table is provided
	print('\n\nExiting, key variables not provided. Required arguments are input audio signal as WAV and an indentifier for this signal')
	parser.print_help()
	sys.exit()


# Otherwise proceed
else:
	signal = args.signal
	name = args.name
	print('\n\nProceeding with ' + signal + '\n')


# Verify file exists
# !os.path.exists(signal) -> giving error?
if os.path.exists(signal) == False:
    print('Error, input signal not found "' + signal + '"')
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
print('\nReading audio signal & measuring tempo')
trackAna = results.AudioValResult(name, signal)
trackAna.setTempo()


# Generate chromagram
print('\nSeparating haromic from percussive signal for chromagram analysis')
trackAna.percusHarmonSep()
trackAna.generateChromagram()


# Set results
print('\nAnalyzing results and summarizing for classifier')
trackAna.analyzeChroma()
trackAna.setResults()


# Write to JSON
outJson = str(name + "-results.json")
with open(outJson, 'w') as outfile:
    json.dump(trackAna.results, outfile)
outfile.close()