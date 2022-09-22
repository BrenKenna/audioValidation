# -*- coding: utf-8 -*-
"""
Created on Fri Aug 26 18:23:25 2022

@author: kenna
"""

# Import required modules
import os, sys
import boto3
import librosa
import soundfile as sf
import numpy as np
import json


# Import resources
from importlib import resources
import io


# Additional imports
import gzip
import base64
import time


# Class to support chunking an audio signal
#   => Consider later making stream unique
class AudioChunkProducer():
    
    def __init__(self, trackName, trackPath, kinesisClient, streamName, partitionKey, userID):
        
        # Initialized attributes
        self.trackName = trackName
        self.trackPath = trackPath
        self.kinesisClient = kinesisClient
        self.streamName = streamName
        self.partitionKey = partitionKey
        self.userID = userID
        
        # Built attributes
        self.audio = None
        self.comprSignal = None
        self.chunkParam = None

        
     # Load track
    def loadTrack(self):
        
        # Crying out for try and except
        y, sr = librosa.load(self.trackPath)
        self.audio = {
            "wave": y,
            "sampleRate": sr,
            "trackLength": int(y.shape[0]/sr)
        }


    # Compress audio signal
    def compressSignal(self):
        self.comprSignal = gzip.compress(base64.encodebytes((self.audio['wave'].tobytes())))


    # Initialize chunking params
    def initChunk(self):

        # Handle state
        if self.audio == None:
            self.loadTrack()
            self.compressSignal()
        
        elif self.comprSignal == None:
            self.compressSignal()

        
        # Return params
        chunkSize = 275000
        self.chunkParam = {
            "Iteration": 0,
            "Chunk Size": chunkSize,
            "N Chunks": int(len(self.comprSignal) / chunkSize),
            "Start": 0,
            "End": chunkSize
        }
    
    
    # Get chunk
    def getChunk(self, chunkLabel):
        
        # Encode slice
        chunkSlice = str(base64.b64encode(
            self.comprSignal[self.chunkParam["Start"]:self.chunkParam["End"]]
        ), 'utf-8')

        # Create record for stream
        chunkData = {
            self.chunkParam["Iteration"]: {
                "Track Name": self.trackName,
                "Sample Rate": self.audio["sampleRate"],
                "Wave": chunkSlice
            }
        }
        
        # Return result
        return chunkData


    # Increment chunk params
    def incrementChunk(self):
        
        # Increment params
        self.chunkParam["Iteration"] += 1
        self.chunkParam["Start"] = (self.chunkParam["End"] + 0)
        self.chunkParam["End"] = (self.chunkParam["End"] + self.chunkParam["Chunk Size"])


    # Post record
    def postChunk(self):
        
        # Fetch data for active chunk
        data = self.getChunk(self.chunkParam["Iteration"])
        
        # Post record
        response = self.kinesisClient.put_record(
            StreamName = self.streamName,
            Data = json.dumps(data),
            PartitionKey = self.partitionKey
        )
        time.sleep(1.25)
        
        # Return response
        print("Posted chunk: " + str(self.chunkParam["Iteration"]))
        return response
        
    
    # Stream audio chunks
    #  Really the entry point
    def streamAudioChunks(self):
        
        # Initialize chunking
        self.initChunk()
        
        # Initialize loop
        while self.chunkParam["End"] < (len(self.comprSignal) + 1) :
            
            # Post active chunk
            self.postChunk()
            
            # Increment
            self.incrementChunk()

            # Handle breach
            if self.chunkParam["End"] > (len(self.comprSignal) + 1) :
                self.postChunk()