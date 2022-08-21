# -*- coding: utf-8 -*-
"""
Created on Sun Aug 21 00:45:27 2022

@author: kenna
"""

# import modules
import librosa
import librosa.display
import numpy as np
import json
import matplotlib.pyplot as plt
import soundfile as sf


# "audioValidator/generator/goat-java.txt"
# Class to build audio from text file
class AudioValGenerator():
    
    def __init__(self, fileName, filePath):
        self.fileName = fileName
        self.filePath = filePath
        self.audioSignal = None
        self.sampleRate = None
    
    # Read file
    def readFile(self):
        with open(self.filePath, "r") as f:
            data = f.readlines()
        f.close()
        return data

    
    # Generate mock audio signal from data
    def generateSignal(self):
        
        # Initialize vars
        mockSignal = []
        data = self.readFile()
        
        # Convert to float array
        for line in data:
            for char in line.replace('\n', ''):
                mockSignal.append(float(ord(char)))
        
        # Convert to np array
        self.audioSignal = np.asarray(mockSignal).astype('float32')
        self.setSampleRate()


    # Set sample rate
    def setSampleRate(self):
        sampleRate = int(0.01 * self.audioSignal.shape[0])
        if sampleRate < 2000:
            self.sampleRate = 2000
        else:
            self.sampleRate = sampleRate


    # Write to wav
    def exportWav(self, outPath):
        sf.write(
            outPath,
            self.audioSignal,
            self.sampleRate
        )