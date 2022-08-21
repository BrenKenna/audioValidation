# -*- coding: utf-8 -*-
"""
Created on Sat Aug 20 18:51:44 2022

@author: kenna
"""


# Import required modules
import os, sys
import librosa
import librosa.display
import numpy as np
import json
import matplotlib.pyplot as plt

from results import results


#################################
# 
# Track analysis
# 
#################################


# Load track
sirDuke = results.AudioValResult('Thorns Crim. Death', 'examples/Thorns-of-Crimson-Death.wav')


# Librosa analysis
sirDuke.percusHarmonSep()
sirDuke.generateChromagram()
sirDuke.setTempo()


# Analyze above results
sirDuke.initializeChromAna() # halfSec = False
'''

(0, 43, 43)

'''

sirDuke.analyzeChroma()


# Summarize
sirDuke.summarizePitchFreq()
sirDuke.setResults()

'''

(105, 1335)

'''


# Print results
print(json.dumps([sirDuke.results], indent = 2))

'''

[
  {
    "Track": "Sir Duke",
    "Track Name": "examples/Sir-Duke.wav",
    "Mean Played/s": 0.875,
    "Mean Not Played/s": 11.125,
    "Played Sum": 105,
    "Not Played Sum": 1335,
    "Played Size": 120,
    "Length seconds": 120,
    "Tempo": 107.666015625,
    "Wave Size": 2646000,
    "Sampling Rate": 22050
  },

  {
    "Track": "Thorns Crim. Death",
    "Track Name": "examples/Thorns-of-Crimson-Death.wav",
    "Mean Played/s": 1.1833333333333333,
    "Mean Not Played/s": 10.816666666666666,
    "Played Sum": 142,
    "Not Played Sum": 1298,
    "Played Size": 120,
    "Length seconds": 120,
    "Tempo": 143.5546875,
    "Wave Size": 2646000,
    "Sampling Rate": 22050
  }
]

'''



#################################
# 
# Track generating
#  10 '_'
# 
#################################


# Import
from generator import generator

# Generate audio signal
goatMal = generator.AudioValGenerator('Collection', 'generator/collection-java.txt')
goatMal.generateSignal()
goatMal.audioSignal.shape
goatMal.sampleRate

# Export to wav: (1102262, 11022)
goatMal.exportWav('generator/collection-java.wav')


# Read and analyze
goatAna = results.AudioValResult('Goat', 'generator/goat-java.wav')
goatAna.percusHarmonSep()
goatAna.generateChromagram()
goatAna.setTempo()


# Analyze chromagram
goatAna.initializeChromAna() # halfSec = False
goatAna.analyzeChroma()


# Summarize results
goatAna.summarizePitchFreq()
goatAna.setResults()
print(json.dumps([goatAna.results], indent = 2))


'''

- Collection only doable with >7M lines of code

[
  {
    "Track": "Goat",
    "Track Name": "generator/goat-java.wav",
    "Mean Played/s": 3.2,
    "Mean Not Played/s": 8.8,
    "Played Sum": 112,
    "Not Played Sum": 308,
    "Played Size": 35,
    "Length seconds": 35,
    "Tempo": 0,
    "Wave Size": 771905,
    "Sampling Rate": 22050
  },
  
  {
    "Track": "Collection",
    "Track Name": "generator/collection-java.wav",
    "Mean Played/s": 1.32,
    "Mean Not Played/s": 10.68,
    "Played Sum": 132,
    "Not Played Sum": 1068,
    "Played Size": 100,
    "Length seconds": 100,
    "Tempo": 0,
    "Wave Size": 2205001,
    "Sampling Rate": 22050
  }
]

'''


#######################
# 
# Build Collection
# 
#######################


# Import required modules
import os, sys
import librosa
import librosa.display
import numpy as np
import json
import matplotlib.pyplot as plt

from results import results


# Setup analysis
output = [ ]
toDo = [
   ('Goat', 'generator/goat-java.wav'),
   ('Collection', 'generator/collection-java.wav'),
   ('Wihing Well', 'examples/Wishing-Well.wav'),
   ('Stomp', 'examples/Stomp.wav'),
   ('Beat Goes on', 'examples/And-the-Beat-Goes-On.wav'),
   ('Sir Duke', 'examples/Sir-Duke.wav'),
   ('Wihing Well', 'examples/Wishing-Well.wav'),
   ('Give Me the Night', 'examples/Give-Me-The-Night.wav'),
   ('Thorns of Crimson Death', 'examples/Thorns-of-Crimson-Death.wav')
]


# Run
for track in toDo:
    trackAna = results.AudioValResult(track[0], track[1])
    trackAna.percusHarmonSep()
    trackAna.generateChromagram()
    trackAna.setTempo()
    trackAna.initializeChromAna() # halfSec = False
    trackAna.analyzeChroma()
    trackAna.summarizePitchFreq()
    trackAna.setResults()
    output.append(trackAna.results)
    del trackAna


# Dump
with open('summaries.json', 'w') as outfile:
    json.dump(output, outfile)


'''

- Sums are still quite different

(0, 43, 43)
(112, 308)
(0, 43, 43)
(132, 1068)

(0, 43, 43)
(132, 1308)
(0, 43, 43)
(125, 1315)
(0, 43, 43)
(111, 1329)
(0, 43, 43)
(105, 1335)
(0, 43, 43)
(132, 1308)
(0, 43, 43)
(113, 1327)
(0, 43, 43)
(142, 1298)

'''


