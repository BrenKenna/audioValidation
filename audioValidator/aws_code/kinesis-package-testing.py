# -*- coding: utf-8 -*-
"""
Created on Sat Aug 27 12:05:54 2022

@author: kenna
"""


# Import modules
import os, sys
import boto3
import numpy as np
import json


# Configure client
# os.chdir('audioValidator/aws_code')
kinesisClient = boto3.client('kinesis')


#############################
#############################
# 
# Test Producer
# 
#############################
#############################


# Import
from audioStreamer import chunkProducer


# Set vars
arn = "arn:aws:kinesis:eu-west-1:017511708259:stream/audioSlices"
streamName = 'audioSlices'
region = 'eu-west-1'
trackPath = "audioStreamer/Stomp.wav"
trackName = "Stomp.wav"
partitionKey = "user-1/" + trackName


# Instantiate producer
audioProd = chunkProducer.AudioChunkProducer(trackName, trackPath, kinesisClient, streamName, partitionKey)


# Produce shards
audioProd.streamAudioChunks()

'''

Posted chunk: 0
Posted chunk: 1
Posted chunk: 2
Posted chunk: 3

'''


#############################
#############################
# 
# Test Consumer
# 
#############################
#############################


# Import
from audioStreamer import chunkConsumer


# Set vars
arn = "arn:aws:kinesis:eu-west-1:017511708259:stream/audioSlices"
streamName = 'audioSlices'
region = 'eu-west-1'
trackPath = "audioStreamer/Stomp.wav"
trackName = "Stomp.wav"
partitionKey = "user-1/" + trackName
sampleRate = audioProd.audio["sampleRate"]
trackLength = audioProd.audio["sampleRate"]

# Instantiate consumer
audioConsumer = chunkConsumer.AudioChunkConsumer(trackName, trackPath, kinesisClient, streamName, partitionKey, sampleRate, trackLength)


# Consume stream
consumeState = audioConsumer.consumeStream(matchPartKey = True)


# Set audio data
audioConsumer.setAudio()


# Checkout
audioConsumer.audio.keys()
audioConsumer.audio['wave'][0:100]
audioConsumer.audio['sampleRate']
audioConsumer.audio['trackLength']


###############
# 
# Old Methods before setAudio()
# 
###############


# Rebuild gzip string
audioConsumer.rebuildGzip(clearTmp = False)


#
# Compare compressed strings
#  is True :)
audioConsumer.comprSignal == audioProd.comprSignal


# Rebuild audio signal: waveShape = (5373817,)
data = audioConsumer.rebuildAudio(clearTmp = False)
data.shape