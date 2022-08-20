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
sirDuke.analyzeChroma()


# Summarize
sirDuke.summarizePitchFreq()
sirDuke.setResults()

sirDuke.results