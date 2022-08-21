# -*- coding: utf-8 -*-
"""
Created on Sat Aug 20 17:55:31 2022

@author: kenna
"""

# Import required modules
import os
import librosa
import librosa.display
import numpy as np
import pandas as pd
import json
import matplotlib.pyplot as plt


# Convert audio signal into chromagram, then summarize
class AudioValResult():
    
    """
    
    """
    
    # Initialize
    def __init__(self, trackName, trackPath, label = None):
        
        # Identifiying attributes
        self.trackName = trackName
        self.trackPath = trackPath
        self.label = label
        self.fileSize = self.getFileStats()
        
        # Core audio
        self.audio = { }
        self.harmonPercuss = None
        self.loadTrack(trackPath)
        
        # Librosa analysis
        self.chromagram = None
        self.tempo = None
        
        # Attribute towards summary
        self.chromaProbs = None
        self.notesPlayed = []
        self.results = { }


    # Get file stats
    def getFileStats(self):
        return os.stat(self.trackPath).st_size / (1024 * 1024)


    # Load track
    def loadTrack(self, trackPath):
        
        # Crying out for try and except
        y, sr = librosa.load(trackPath, duration = 120)
        self.audio = {
            "wave": y,
            "sampleRate": sr,
            "trackLength": int(y.shape[0]/sr)
        }
        self.setTempo()


    # Separate harmonic from percussion
    #  Does this work with example text?
    def percusHarmonSep(self):
        y_harmonic, y_percussive = librosa.effects.hpss(self.audio["wave"])
        self.harmonPercuss = {
            "harmon": y_harmonic,
            "percuss": y_percussive
        }


    # Set chromagram
    def generateChromagram(self):
        
        # Separate harmonic from percussive signals
        if self.harmonPercuss == None:
            self.percusHarmonSep()
        
        # Need to consider the rate here
        self.chromagram = librosa.feature.chroma_cqt(
            y = self.harmonPercuss["harmon"],
            sr = self.audio["sampleRate"]
        )


    # Analyze tempo
    def setTempo(self):
        tempo, beat_frames = librosa.beat.beat_track(
            y = self.audio["wave"],
            sr = self.audio["sampleRate"]
        )
        self.tempo = tempo


    # Initialize results from analyzing chromagram
    def initializeChromAna(self, halfSec = False):
        
        
        # Initialize results object
        self.chromaProbs = [ [ ] for rows in range(self.chromagram.shape[0]) ]
        strt = 0
        end = int( self.chromagram.shape[1] / self.audio["trackLength"] )
        
        # Analyze pitch occurence to half a second
        #  Point that can cause issues
        if halfSec:
            end = int(end / 2)
        step = (end + 0)
        return strt, end, step


    # Generate and analyze chromagram
    def analyzeChroma(self):
        
        # Run perconditions
        self.generateChromagram()
        strt, end, step = self.initializeChromAna()
        
        # Perform hard filtering on slices within bounds
        while end < (self.chromagram.shape[1] + 1):
            
            # Sanity check vars
            iters = 0
            pitchCounter = 0
            
            # Hard filter each pitch in chromagram
            for pitch in self.chromagram:
                
                # Extract slice
                pitchSlice = pitch[strt:end]
                for elm in range(0, len(pitchSlice)):
                    
                    # Set null pitch
                    if pitchSlice[elm] < 0.8:
                        pitchSlice[elm] = 0
                        
                    # Otherwise round up
                    else:
                        pitchSlice[elm] = 1
                
                # Append frequency of pitch in slice
                self.chromaProbs[pitchCounter].append( float(np.sum(pitchSlice)/len(pitchSlice)) )
                pitchCounter+=1
                
            # Handle next slice iteration
            pitchCounter = 0
            iters+=1
            strt = (end+1)
            end = (end + step)

        # Update reults to a float-32 np array
        self.chromaProbs = np.asarray(self.chromaProbs).astype('float32')


    # Summarize pitch
    #  Currently doubles itself, while averages are accurate
    def summarizePitchFreq(self):
        
        # Data for results
        self.notesPlayed = []
        playedSum = 0
        nullSum = 0
        
        # Summarize each time point
        for i in range(0, self.chromaProbs.shape[1]):
            
            # Collected data
            rangeCount = 0
            nullOthers = 0
            
            # Count occurence of each pitch basically
            for pitch in range(0, 12):
                
                # Boundary for detected pitch
                if self.chromaProbs[pitch][i] >= 0.5:
                    rangeCount += 1
                    playedSum += 1
                
                # Otherwise contributes to noise
                else:
                    nullOthers += 1
                    nullSum += 1
            
            # Append pitch count tuple
            data = tuple( ( rangeCount, nullOthers ) )
            self.notesPlayed.append(data)
            
        # Return
        return playedSum, nullSum


    # Set results
    def setResults(self):
        
        # Fetch summary
        playedSum, nullSum = self.summarizePitchFreq()


        #
        # Set reults object
        # For whatever the output is twice the size as notes
        #  values for sum etc are correct
        #  adjusting those by this yeilds same results.
        #
        # Shape of expected "self.chromProbs" is correct for
        #  the "Sir-Duke.wav" track @120 and indent look good. 
        #       But the resulting length is 240?
        #
        # Moving on with life, but will comeback periodically
        #  because priorities are now Generator class & AWS stuff
        # 
        self.results = {
            "Track": self.trackName,
            "Track Name": self.trackPath,
            "Mean Played/s": playedSum / int(len(self.notesPlayed)),
            "Mean Not Played/s": nullSum / int(len(self.notesPlayed)),
            "Played Sum": playedSum,
            "Not Played Sum": nullSum,
            "Played Size": int(len(self.notesPlayed)),
            "Length seconds": int(self.audio["trackLength"]),
            "Tempo": self.tempo,
            "Wave Size": self.audio["wave"].shape[0],
            "Sampling Rate": self.audio["sampleRate"],
            "File Size MB": self.fileSize,
            "MB / s": self.fileSize / int(self.audio["trackLength"])
        }
        if self.label != None:
            self.results.update({
                "Label": self.label
            })
        if self.tempo != 0:
            notesOvrTemp = playedSum / self.tempo
        else:
            notesOvrTemp = 0
        self.results.update({
            "Notes / Tempo": notesOvrTemp
        })


    # Return results as row for comparator
    def getResultsAsRow(self):
        return pd.DataFrame.from_dict(self.results, orient='index').transpose()
    
    
    
    
    
    
    
    
    
    
    
    
    