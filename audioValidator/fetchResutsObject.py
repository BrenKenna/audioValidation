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


# Load track
sirDuke = results.AudioValResult('Sir Duke', 'examples/Sir-Duke.wav')


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
    "Mean Played/ half-s": 0.875,
    "Mean Not Played/ half-s": 11.125,
    "Played Sum": 105,
    "Not Played Sum": 1335,
    "Played Size": 120,
    "Length seconds": 120,
    "Tempo": 107.666015625,
    "Wave Size": 2646000,
    "Sampling Rate": 22050
  }
]

'''
