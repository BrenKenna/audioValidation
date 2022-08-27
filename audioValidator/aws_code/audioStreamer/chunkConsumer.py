# -*- coding: utf-8 -*-
"""
Created on Fri Aug 26 18:23:41 2022

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



# Consume stream
class AudioChunkConsumer():
    
    # Initialize object
    def __init__(self, trackName, trackPath, kinesisClient, streamName, partitionKey, sampleRate, trackLength):
        
        # Initialized attributes
        self.trackName = trackName
        self.trackPath = trackPath
        self.kinesisClient = kinesisClient
        self.streamName = streamName
        self.partitionKey = partitionKey
        self.sampleRate = sampleRate
        self.trackLength = trackLength
        
        
        # Built attributes
        self.streamMetaData = {}
        self.consumeParam = None
        self.audioLabels = []
        self.audioChunks = [ ]
        self.comprSignal = None
        self.audio = {}


    # Rebuild compressed signal
    def rebuildGzip(self, clearTmp = True):
        
        # Initialize before joining
        self.comprSignal = base64.b64decode(self.audioChunks[0][str(0)]['Wave'])
        for i in range(1, len(self.audioChunks)):
            activeByte = base64.b64decode(self.audioChunks[i][str(i)]['Wave'])
            self.comprSignal = b"".join([self.comprSignal, activeByte])

        # Handle clearing tmp data
        if clearTmp:
            self.audioChunks = []
    
    
    # Rebuild audio object
    def rebuildAudio(self, clearTmp = True):
        
        # Decompress & decode to byte array
        rebuiltBytes = base64.decodebytes(gzip.decompress(self.comprSignal))

        # Read numpy from buffer
        finalSignal = np.frombuffer(rebuiltBytes, dtype="float32")
        
        # Handle clearing temp data
        if clearTmp:
            self.comprSignal = None

        # Return audio signal
        return finalSignal
    
    
    # Set audio
    def setAudio(self, clearTmp = True):
        
        # Rebuild audio dict
        self.rebuildGzip(clearTmp)
        
        # Rebuild audio signal
        audioSignal = self.rebuildAudio(clearTmp)
        
        # Set audio dict
        self.audio = {
            "wave": audioSignal,
            "sampleRate": self.sampleRate,
            "trackLength": self.trackLength
        }


    # Initialize consume params
    def initConsumeParam(self, initial = True):
        
        # Assume first call
        if initial:
            
            # Data holders
            self.audioLabels = []
            self.audioChunks = []
            
            # Params
            self.consumeParam = {
                "Zero Streak": 0,
                "Dup Record": 0,
                "Iteration": 0,
                "Sub-Iteration": 0,
            }
            
        # Otherwise handle next nest
        else:
            self.consumeParam["Zero Streak"] = 0
            self.consumeParam["Dup Record"] = 0
            self.consumeParam["Sub-Iteration"] = 0


    # Handle record
    def addRecord(self, record, matchPartitionKey = False):
        
        # Read data
        data = json.loads(record['Data'])
        label = int(list(data.keys())[0])

        # Append if new
        if label not in self.audioLabels:

            # Handle matching partition key
            if matchPartitionKey:
                if record["PartitionKey"] == self.partitionKey:
                    self.audioLabels.append(label)
                    print("Added record from " + str(self.consumeParam["Iteration"]) + ", label = " + str(label))
                    self.audioChunks.append(data)
                    # print("Size is now: " + str(len(self.audioChunks)))
                    
                #else:
                #    print("Partition Keys do not match:")
                #    print("Supplied: " + self.partitionKey)
                #    print("Returned: " + record["PartitionKey"])

            # Otherwise proceed
            else:
                self.audioChunks.append(data)

        # Otherwise pass
        else:
            print("Returned record already exists, " + str(label))
            self.consumeParam["Dup Record"] += 1


    # Read records
    def consumeShard(self, response, matchPartKey):

        # Consume data from shard
        self.initConsumeParam(initial = False)
        while 'NextShardIterator' in response and self.consumeParam["Zero Streak"] < 3:

            # Note empty results
            if len(response["Records"]) == 0:
                self.consumeParam["Zero Streak"] += 1
                
            # Else check distinct record
            else:
                
                # Add unique records
                while len(response["Records"]) > 0 and self.consumeParam["Dup Record"] < 3 :
                    self.addRecord(response["Records"].pop(0), matchPartitionKey = matchPartKey)
            
            # Acknowledge loop breaches
            if self.consumeParam["Zero Streak"] > 3:
                print("Terminating loop after 3 consecutive zeros")
            
            # Get records from iter
            shardIt = response['NextShardIterator']
            response = self.kinesisClient.get_records(
                ShardIterator = shardIt
            )


    # Get metadata and initalize params
    def setMetaData(self):
        
        # Set meta data for stream name
        self.streamMetaData = self.kinesisClient.describe_stream(
            StreamName = self.streamName
        )
        self.initConsumeParam()


    # Consume stream
    def consumeStream(self, matchPartKey = False):
        
        # Fetch metadata
        #  Should instead handle a 'ResourceNotFoundException',
        #   however the if statements captures
        self.setMetaData()

        # Do not proceed if metadata is empty
        if "StreamDescription" not in self.streamMetaData:
            print("Exiting from consuming a non-existent stream")
            return -1
        
        # Consume stream
        for shard in self.streamMetaData['StreamDescription']['Shards']:
            
            # Fetch an iterator for the shard
            shardIter = self.kinesisClient.get_shard_iterator(
                StreamName = self.streamName,
                ShardId = shard['ShardId'],
                ShardIteratorType = 'AT_SEQUENCE_NUMBER',
                StartingSequenceNumber = shard['SequenceNumberRange']['StartingSequenceNumber']
            )

            # Get records from iter
            response = self.kinesisClient.get_records(
                ShardIterator = shardIter['ShardIterator']
            )
            
            # Consume shard
            self.consumeShard(response, matchPartKey)
            self.consumeParam["Iteration"] += 1
            # print("\n\nSize after this shards: " + str(len(self.audioChunks)))
        
        # Return iterations
        # print("\n\nSize after all shards: " + str(len(self.audioChunks)))
        return self.consumeParam["Iteration"]