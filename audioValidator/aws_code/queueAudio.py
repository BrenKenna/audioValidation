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
from aws_code.queueManager import manager
from aws_code.audioStreamer import chunkProducer
from aws_code.audioStreamer import chunkConsumer


# Class to support producing & consuming the audio streams under a queue
class QueuedAudio():
    
    # Attributes
    def __init__(self, kinesisClient, queueMngr, audioProducer):
        
        # Producers instantiated externally
        self.kinesisClient = kinesisClient
        self.audioProducer = audioProducer
        self.queueMngr = queueMngr
        self.queueName = queueMngr.queueName

        # Set core variables
        self.trackName = audioProducer.trackName
        self.userID = audioProducer.userID
        self.trackPath = audioProducer.trackPath
        self.sampleRate = None
        self.trackLength = None

        # Audio dict
        self.audio = {}

    # Stream audio & enqueue
    def enqueueStream(self, clearProducer = False):
        
        # Shard & stream audio
        self.audioProducer.streamAudioChunks()
        self.sampleRate = self.audioProducer.audio['sampleRate']
        self.trackLength = self.audioProducer.audio['trackLength']
        
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
    def setProducer(self, audioProducer):
        self.audioProducer = audioProducer
        self.trackName = audioProducer.trackName
        self.userID = audioProducer.userID
        self.trackPath = audioProducer.trackPath


    # Poll an audio stream
    def pollAudioStream(self, streamName):
        
        # Poll audio
        print('\nPolling message')
        # message = self.queueMngr.getMsg()
        message = self.queueMngr.pollMsg()
        if message == None:
            print('\nQueue has been consumed')
            return True

        # Instantiate consumer from message
        print('\nCreating consumer')
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
        print('\nConsuming audio stream for track: ' + consumerData['PartitionKey'])
        consumeState = audioConsumer.consumeStream(matchPartKey = True)
        if consumeState != -1:

            # Rebuild audio signal & set attributes on consumer
            print('\nRebuilding audio stream')
            audioConsumer.setAudio()
            
            # Output audio dict
            self.audio = audioConsumer.audio