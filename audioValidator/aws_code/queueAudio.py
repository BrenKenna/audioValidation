# -*- coding: utf-8 -*-
"""
Created on Wed Sep 21 15:05:35 2022

@author: kenna
"""

# Import required modules
import os, sys
import boto3
import json


# Packae modules
from queueManager import manager
from audioStream import chunkConsumer
from audioStream import chunkConsumer


# Class to support producing & consuming the audio streams under a queue
class QueuedAudio():
    
    # Attributes
    def __init__(self, chunkProducer, queueMngr):
        
        # Producers instantiated externally
        self.kinesisClient = boto3.client('kinesis')
        self.chunkProducer = chunkProducer
        self.queueMngr = queueMngr
        self.queueName = queueMngr.queueName

        # Set core variables
        self.trackName = chunkProducer.trackName
        self.userID = chunkProducer.userID
        self.trackPath = chunkProducer.trackPath
        self.sampleRate = chunkProducer.sampleRate
        self.trackLength = chunkProducer.trackLength        


    # Stream audio & enqueue
    def enqueueStream(self, clearProducer = False):
        
        # Shard & stream audio
        self.chunkProducer.streamAudioChunks()
        
        # Enqueue sharded audio stream
        data = (
            self.userID,
            self.trackName,
            self.trackPath,
            self.sampleRate,
            self.trackLength
        )
        self.queueMngr.sendMsg(data)
        
        # Clear producer
        if clearProducer == True:
            self.chunkProducer = None


    # Drop producer
    def clearProducer(self):
        self.chunkProducer = None


    # Clear track data
    def clearTrackData(self):
        self.trackName = None
        self.userID = None
        self.trackPath = None


    # Clean up
    def removeActiveProducerData(self):
        self.clearProducer()
        self.clearTrackData()
        

    # Set producer
    def setProducer(self, chunkProducer):
        self.chunkProducer = chunkProducer
        self.trackName = chunkProducer.trackName
        self.userID = chunkProducer.userID
        self.trackPath = chunkProducer.trackPath


    # Poll an audio stream
    def pollAudioStream(self, streamName):
        
        # Poll audio
        message = self.queueMngr.pollMsg()
        if message == None:
            print('\nQueue has been consumed')
            return True

        # Instantiate consumer from message
        consumerData = json.loads(message['Body'])
        audioConsumer = chunkConsumer.AudioChunkConsumer(
            consumerData['TrackName'],
            consumerData['TrackPath'],
            self.kinesisClient,
            streamName,
            consumerData['PartitionKey'],
            consumerData['SampleRate'],
            consumerData['TrackLength']
        )

        # Consume sharded audio stream for the partition key
        consumeState = audioConsumer.consumeStream(matchPartKey = True)
        if consumeState != -1:

            # Rebuild audio signal & set attributes on consumer
            audioConsumer.setAudio()