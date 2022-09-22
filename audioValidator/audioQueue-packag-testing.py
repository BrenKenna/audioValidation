# -*- coding: utf-8 -*-
"""
Created on Thu Sep 22 10:07:20 2022

@author: kenna
"""


# Import required modules
import os, sys
import boto3
import json


# Stream modules
from aws_code.audioStreamer import chunkProducer
from aws_code.audioStreamer import chunkConsumer


# Queue module
from aws_code.queueManager import manager


# Audio stream en/dequeuer
from aws_code import queueAudio


#########################################
#########################################
# 
# Test Audio Queue Package
# 
#########################################
#########################################


# Instantiate queue manager
queueName = 'TracksQueue'
queueMng = manager.QueueManager(queueName)


# Create queue
queueMng.createQueue(delaySec = 10, timeout = 60)


# Get the queue
queueMng.getQueue()


# Instantiate: Wishing-Well.wav
arn = "arn:aws:kinesis:eu-west-1:017511708259:stream/audioSlices"
streamName = 'audioSlices'
userID = 'user-YYZ'
region = 'eu-west-1'
trackPath = 'aws_code/Wishing-Well.wav'
trackName = 'Wishing-Well'
partitionKey = "user-YYZ/" + trackName
kinesisClient = boto3.client('kinesis')


# Instantiate producer
audioProd = chunkProducer.AudioChunkProducer(
    trackName,
    trackPath,
    kinesisClient,
    streamName,
    partitionKey,
    userID
)


# Instantiate audio queuer
audioQueuer = queueAudio.QueuedAudio(kinesisClient, queueMng, audioProd)


# Stream & enqueue
audioQueuer.enqueueStream()


# Poll first message
audioQueuer.pollAudioStream(streamName)


# Log output
audioQueuer.audio.keys()


