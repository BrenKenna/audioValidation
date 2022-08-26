# -*- coding: utf-8 -*-
"""
Created on Thu Aug 25 10:38:32 2022


Core issue is rebuilding tracks
    -> Not seeing a point given that blocks will have to be rebuilt
        => A parition label becomes S3 prefix, in their each block is written
            => When done, all are fetched, then restored in order

        => S3 as a data-lake much simpler, currently over complicates it
        
        => Nice experiment though
        
    -> Running questions:
        1. How to handle conflicts with multiple consumers?
        2. What are simple vs overly complicated uses?
        3. When should people use kinesis instead of S3?
        4. Do people ever work with shards of data?
            => Say rebuiling 20MB file from N 4MB shards?
        5. Other reasons to go MSK sides the size of input stream?

Links:
    Kinesis with maximum of 200MB/s:
        https://docs.aws.amazon.com/code-samples/latest/catalog/python-kinesis-streams-kinesis_stream.py.html
        https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/kinesis.html#Kinesis.Client.put_record


    Managed Streaming with Kafka
        https://docs.aws.amazon.com/msk/1.0/apireference/operations.html
        https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/kafka.html
        https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/kafkaconnect.html
        
    Kafka Python
        https://kafka-python.readthedocs.io/en/master/

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



###############################
###############################
# 
# Sanity Check Config
# 
###############################
###############################


# List objects in bucket
s3 = boto3.resource('s3')
my_bucket = s3.Bucket('bandcloud')
for my_bucket_object in my_bucket.objects.all():
    print(my_bucket_object)


'''

s3.ObjectSummary(bucket_name='bandcloud', key='test')
s3.ObjectSummary(bucket_name='bandcloud', key='test/recording.ogg')
s3.ObjectSummary(bucket_name='bandcloud', key='test/site_acoustic_guitar.mp3')

'''



#####################################
#####################################
# 
# Compression & Deompression
# 
#####################################
#####################################


# Import modules
import gzip


# Read data and compress
trackPath = "examples/Stomp.wav"
trackName = "Stomp.wav"
audioSignal, sampleRate = librosa.load(trackPath)
compressedSignal = gzip.compress(audioSignal.tobytes())


# Retrieve
finalSignal = np.frombuffer(gzip.decompress(compressedSignal), dtype="float32")


# Compare sizes
sys.getsizeof(compressedSignal)
sys.getsizeof(finalSignal)

'''

sys.getsizeof(compressedSignal)
Out[56]: 19892280

sys.getsizeof(audioSignal)
Out[57]: 21495364

sys.getsizeof(audioSignal.tobytes())
Out[58]: 21495301

'''



#####################################
#####################################
# 
# Send Gzipped Wav
# 
#####################################
#####################################


#
import base64


# Vars
arn = 'arn:aws:kinesis:eu-west-1:017511708259:stream/audioSlices'
streamName = 'audioSlices'
region = 'eu-west-1'
trackPath = "examples/Stomp.wav"
trackName = "Stomp.wav"
partitionKey = "user-1/" + trackName


# Configure client
kinesis_client = boto3.client('kinesis')


# Read data and compress
audioSignal, sampleRate = librosa.load(trackPath)
comprSignal = gzip.compress(base64.encodebytes((audioSignal.tobytes())))


# Create data object to send: 1040000
data = {
    "Track Name": trackName,
    "Sample Rate": sampleRate,
    "Wave": str(comprSignal)
}


# Send data
response = kinesis_client.put_record(
    StreamName = streamName,
    Data = json.dumps(data),
    PartitionKey = partitionKey
)


'''

- Breaks for the full dataset, works fine for smaller subset
    => Error comes about due to 2 MB/s limit

Connection was closed before we received a valid response from endpoint URL: "https://kinesis.eu-west-1.amazonaws.com/".


- Tried with on demand limit still the same as above

- Size issue with subset 0:724312

ClientError: An error occurred (ValidationException) when calling the PutRecord operation: 1 validation error detected: Value at 'data' failed to satisfy constraint: Member must have length less than or equal to 1048576

'''



####################################
####################################
# 
# Chunk Streams
# 
####################################
####################################


#########################
#########################
#
# Slice
#
#########################
#########################


# Import for sleeping 2s
import time


# Set vars
arn = 'arn:aws:kinesis:eu-west-1:017511708259:stream/audioChunks'
streamName = 'audioChunks'
region = 'eu-west-1'
trackPath = "examples/Stomp.wav"
trackName = "Stomp.wav"
partitionKey = "user-1/" + trackName


# Distribute work todo per process
chunkSize = 275000
nChunks = int(len(comprSignal) / chunkSize)
strt = 0
end = (chunkSize + 0)


# Iterator
chunkLabel = -1
while end < (len(comprSignal) + 1) :
    
    # Configure slice
    chunkLabel += 1
    data = {
        chunkLabel: {
            "Track Name": trackName,
            "Sample Rate": sampleRate,
            "Wave": str(base64.b64encode(comprSignal[strt:end]), 'utf-8')
        }
    }

    # Send data
    response = kinesis_client.put_record(
        StreamName = streamName,
        Data = json.dumps(data),
        PartitionKey = partitionKey
    )
    print("Posted chunk: " + str(chunkLabel))

    # Increment window
    strt = (end + 0)
    end = (end + chunkSize)
    time.sleep(1.25)
    
    # Handle breach
    if end > (len(comprSignal) + 1):
        print("Sending last stream:" + str(strt) + "-" + str(len(comprSignal)))
        chunkLabel += 1
        data = {
            chunkLabel: {
                "Track Name": trackName,
                "Sample Rate": sampleRate,
                "Wave": str(base64.b64encode(comprSignal[strt::]), 'utf-8')
            }
        }
    
        # Send data
        response = kinesis_client.put_record(
            StreamName = streamName,
            Data = json.dumps(data),
            PartitionKey = partitionKey
        )



# 
print(chunkLabel)


'''

json = {'data': base64.encodebytes(comprSignal[0:100])}
base64.decodebytes(json['data'])


str(var)
Out[340]: "b'H4sIAE5SB2MC/+zbyZqiSBQF4D2v4kIFIsAlAioKhAjIsGOeZyIRnr6j3qGX9K67Mv9Phrj3nKxs\\nQfj//qGEHduxHduxHduxHduxHduxHduxHduxHduxHduxHduxHduxHduxHQ==\\n'"

bytes(var)
Out[341]: b'H4sIAE5SB2MC/+zbyZqiSBQF4D2v4kIFIsAlAioKhAjIsGOeZyIRnr6j3qGX9K67Mv9Phrj3nKxs\nQfj//qGEHduxHduxHduxHduxHduxHduxHduxHduxHduxHduxHduxHduxHQ==\n'


0-79

'''


#########################
#########################
#
# Re-build
#
#########################
#########################


# Set vars
arn = 'arn:aws:kinesis:eu-west-1:017511708259:stream/audioChunks'
streamName = 'audioChunks'
region = 'eu-west-1'
trackPath = "examples/Stomp.wav"
trackName = "Stomp.wav"
partitionKey = "user-1/" + trackName


# Distribute work todo per process
chunkSize = 275000
nChunks = int(len(comprSignal) / chunkSize)
strt = 0
end = (chunkSize + 0)
expected = 79



# Describe stream, expected and got 8 shards
streamMetaData = kinesis_client.describe_stream(
    StreamName = streamName
)
streamMetaData['StreamDescription'].keys()
len(streamMetaData['StreamDescription']['Shards'])

'''

Out[153]: dict_keys(['StreamName', 'StreamARN', 'StreamStatus', 'Shards', 'HasMoreShards', 'RetentionPeriodHours', 'StreamCreationTimestamp', 'EnhancedMonitoring', 'EncryptionType'])

8

'''


# Stream summary
response = kinesis_client.describe_stream_summary(
    StreamName = streamName
)
response['StreamDescriptionSummary'].keys()

'''

Out[160]: dict_keys(['StreamName', 'StreamARN', 'StreamStatus', 'RetentionPeriodHours', 'StreamCreationTimestamp', 'EnhancedMonitoring', 'EncryptionType', 'OpenShardCount', 'ConsumerCount'])



{'StreamName': 'audioSlices',
 'StreamARN': 'arn:aws:kinesis:eu-west-1:017511708259:stream/audioSlices',
 'StreamStatus': 'ACTIVE',
 'RetentionPeriodHours': 24,
 'StreamCreationTimestamp': datetime.datetime(2022, 8, 25, 12, 44, 13, tzinfo=tzlocal()),
 'EnhancedMonitoring': [{'ShardLevelMetrics': []}],
 'EncryptionType': 'NONE',
 'OpenShardCount': 8,
 'ConsumerCount': 0}

'''



###########
# 
# Get
# 
###########


# Set vars
arn = 'arn:aws:kinesis:eu-west-1:017511708259:stream/audioChunks'
streamName = 'audioChunks'
region = 'eu-west-1'
trackPath = "examples/Stomp.wav"
trackName = "Stomp.wav"
partitionKey = "user-1/" + trackName



# Describe stream, expected and got 8 shards
streamMetaData = kinesis_client.describe_stream(
    StreamName = streamName
)

# Check each shard
chunkLabels = []
chunkData = []

counter = -1
for shard in streamMetaData['StreamDescription']['Shards']:
    counter += 1
    shardIter = kinesis_client.get_shard_iterator(
        StreamName = streamName,
        ShardId = shard['ShardId'],
        ShardIteratorType = 'AT_SEQUENCE_NUMBER',
        StartingSequenceNumber = shard['SequenceNumberRange']['StartingSequenceNumber']
    )


    # Get records from iter
    response = kinesis_client.get_records(
        ShardIterator = shardIter['ShardIterator']
    )
    print("Iter-" + str(counter) + " has N = '" + str(len(response['Records'])) + "' records")
    
    # Keep goin
    subCounter = 0
    zeroStreak = 0
    recordsError = 0
    while 'NextShardIterator' in response and zeroStreak < 3 and recordsError < 3:

        # Note empty results
        if len(response['Records']) == 0:
            zeroStreak += 1
            
        # Else check distinct record
        else:
            records = response['Records']
            for record in records:
                data = json.loads(record['Data'])
                label = int(list(data.keys())[0])
                if label not in chunkLabels:
                    chunkLabels.append(label)
                    print("Added record from " + str(counter) + ", label = " + str(label))
                    chunkData.append(data)
                else:
                    print("Returned record already exists, " + str(label))
                    recordsError += 1
        
        # Handle streak
        if zeroStreak > 3:
            print("Terminating loop after 3 consecutive zeros")
        
        # Get records from iter
        shardIt = response['NextShardIterator']
        response = kinesis_client.get_records(
            ShardIterator = shardIt
        )
        print("Iter-" + str(counter) + "-" + str(subCounter) + " has N = '" +  str(len(response['Records'])) + "' records")



'''

- Above works and came back in order

Iter-3 has N = '0' records
Iter-3-0 has N = '0' records
Iter-3-0 has N = '0' records
Iter-3-0 has N = '0' records
Iter-4-0 has N = '0' records
Iter-5 has N = '8' records
Added record from 5, label = 0
Added record from 5, label = 1
Added record from 5, label = 2
Added record from 5, label = 3
Added record from 5, label = 7
Iter-5-0 has N = '8' records


...


Iter-5-0 has N = '8' records
Added record from 5, label = 72
Added record from 5, label = 73
Added record from 5, label = 74
Added record from 5, label = 75
Added record from 5, label = 76
Added record from 5, label = 77
Added record from 5, label = 78
Added record from 5, label = 79

...

Iter-6 has N = '8' records
Returned record already exists, 0
Returned record already exists, 1
Returned record already exists, 2
Returned record already exists, 3
Returned record already exists, 4
Returned record already exists, 5
Returned record already exists, 6
Returned record already exists, 7
Iter-6-0 has N = '8' records
Iter-7 has N = '0' records
Iter-7-0 has N = '0' records
Iter-7-0 has N = '0' records
Iter-7-0 has N = '0' records

'''


# Scope out results
out = base64.b64decode(chunkData[0][str(0)]['Wave'])
for i in range(1, len(chunkData)):
    activeByte = base64.b64decode(chunkData[i][str(i)]['Wave'])
    out = b"".join([out, activeByte])



# Decompress
rebuiltArrayBytes = gzip.decompress(out)
rebuiltBytes = base64.decodebytes(rebuiltArrayBytes)
finalSignal = np.frombuffer(rebuiltBytes, dtype="float32")


'''

- Had an issue where each chunk was missing a byte, basically just
    evaluated slices around boundaries & updated code


finalSignal.shape
Out[443]: (5373817,)

chunkData[0][str(0)]['Sample Rate']
Out[444]: 22050

chunkData[0][str(0)]['Track Name']
Out[445]: 'Stomp.wav'


audioSignal.shape
Out[430]: (5373817,)


- Debug

base64.b64decode(chunkData[0][str(0)]['Wave'])[0:20]
comprSignal[0:20]

'''



###########################################################
###########################################################
# 
# Kafka Producer Consumer
# 
###########################################################
###########################################################



# Producer example
from kafka import KafkaProducer
producer = KafkaProducer(bootstrap_servers='localhost:1234')
for _ in range(100):
    producer.send('foobar', b'some_message_bytes')



# Consumer example
from kafka import KafkaConsumer
consumer = KafkaConsumer('my_favorite_topic')
for msg in consumer:
    print (msg)