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
parser = argparse.ArgumentParser(description = "Generate a mock audio signal from an input text file", formatter_class = argparse.RawTextHelpFormatter)


# Arguments
parser.add_argument("-m", "--mockData", action = 'store', type = str, help = "Input data to convert\n")
parser.add_argument("-o", "--output", action = 'store', type = str, help = "Output for mock audio signal WAV\n")
parser.add_argument("-n", "--name", action = 'store', type = str, help = "Identifier for mock audio signal WAV\n")
args = parser.parse_args()


# Exit if key argument are not supplied
if args.mockData == None or args.name == None:

	# Exit if no table is provided
	sys.stdout.write('\n\nExiting, key variables not provided. Required arguments are input audio signal as WAV and an indentifier for this signal')
	parser.print_help()
	sys.exit()


# Otherwise proceed
else:
	mockData = args.mockData
	name = args.name
	sys.stdout.write('\n\nProceeding with ' + mockData + '\n')


# Verify file exists
# !os.path.exists(signal) -> giving error?
if os.path.exists(mockData) == False:
    sys.stdout.write('Error, input data not found "' + mockData + '"')
    sys.exit()



###################################
###################################
#
# Run generator
#
###################################
###################################


# Audio validator modules
from generator import generator
from results import results
from comparator import comparator


# Generate audio signal
mockSignal = generator.AudioValGenerator(name, mockData)
mockSignal.generateSignal()


# Export to wav: (1102262, 11022)
mockSignal.exportWav(str(name + "-mock-signal.wav"))
sys.stdout.write(
    "\nSignal generated for:\t" + str(name) + "\n" +
    "Generated wave:\t" + str(mockSignal.audioSignal.shape[0])
    + "\nSampling Rate:\t" + str(mockSignal.sampleRate)
+ "\n")