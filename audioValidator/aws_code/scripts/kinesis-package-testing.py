# -*- coding: utf-8 -*-
"""
Created on Sat Aug 27 12:05:54 2022


- Could very much make do with base model classes
    1. Audio
    2. Stream daata

- Can now look at putting a queue around consumption:
    a). Creating & using
    b). Data for each queue element

- Can also consider given main deployment into replicate AZs:
    - Each subnet having a number of baseline streams to read/write to
    - Auto-scaling the available streams for each subnet
    - Allowing and blocking new writes to these streams
    - Deleting these streams once consumed
    
    => At the least requires the idea of:
        a). AutoScaler module
        b). Creator package
        c). Destroyer package
        d). Manager package

    => It will allow the stream aspect to work like a data funnel,
        before data touches storage & better optimize consuming
        the filteration system.
        
    => It also means that while a users project will distributed
        across multiple streams. A single track from a project will
        be located in a single stream
    
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