# -*- coding: utf-8 -*-
"""
Created on Sun Aug 28 17:03:13 2022

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


############################################################################
############################################################################
#
# Lay of the land
#  Message format a little different than initially expected
#  FIFO Queue polls one message at a time
#
############################################################################
############################################################################


# Get the service resource
sqsClient = boto3.client('sqs')


# Create queue
queue = sqsClient.create_queue(
    QueueName = 'test.fifo',
    Attributes = {
        'DelaySeconds': '0',
        'FifoQueue': 'true',
        'VisibilityTimeout': '1'
    }
)


'''

{'QueueUrl': 'https://eu-west-1.queue.amazonaws.com/017511708259/test.fifo',
 'ResponseMetadata': {'RequestId': 'dda37d0d-c818-5081-9cbd-26885d2431e7',
  'HTTPStatusCode': 200,
  'HTTPHeaders': {'x-amzn-requestid': 'dda37d0d-c818-5081-9cbd-26885d2431e7',
   'date': 'Sun, 28 Aug 2022 16:08:28 GMT',
   'content-type': 'text/xml',
   'content-length': '331'},
  'RetryAttempts': 0}}

'''


# Add messages
queueUrl = queue['QueueUrl']
toDo = [
   ('user-1', 'FeelSoNumb', 'examples/test/Feel-So-Numb.wav'),
   ('user-2', 'DeathGodOfThunder', 'examples/test/God-of-Thunder.wav'),
   ('user-1', 'Melechesh1', 'examples/test/Grand-Gathas-of-Baal-Sin.wav'),
   ('user-2', 'Superbeast', 'examples/test/Superbeast.wav'),
   ('user-3', 'Melechesh2', 'examples/test/Tempest-Temper-Enlil-Enraged.wav')
]


for item in toDo:
    partitionKey = str(item[0] + "/" + item[1])
    sqsClient.send_message(QueueUrl = queue['QueueUrl'], MessageBody = partitionKey, MessageGroupId = item[0], MessageDeduplicationId = partitionKey)




# Get messages
response = sqsClient.receive_message(QueueUrl = queueUrl)
response.keys()
len(response['Messages'])
response['Messages'][0].keys()

'''


Out[30]: dict_keys(['Messages', 'ResponseMetadata'])
1
dict_keys(['MessageId', 'ReceiptHandle', 'MD5OfBody', 'Body'])


- First call

{'MessageId': '049ff2ed-e842-40df-9134-337ee454adea',
  'ReceiptHandle': 'AQEBCp6LVQDupZULSgrJ6Vnkobp0iHaQ43ki7lx76zmWB2QrGEMh/ckZXt74Qd6f/y0w4SbNK4tLcDmGqaVhZIdUeIRhjxFG/2iNrHc+7uRHCH9QNTH0G+vdQkcYE3F9aA6MZ+WHFKyDx1ohahqWydK58JJuuJk/bnUpUrQQE8BEGwkQuTmPwVPqcmzjD3ChPfSw+GHVFEKtQmg1eijm9z7K0PNElvUTZeAVljBNL/Lw+w/QDcMyWsij9k9uZt5L5niZ0j4DuRXsH2ktyu6TOjDovw==',
  'MD5OfBody': '99d858ef8750d3ff9f3ca3a8654582aa',
  'Body': 'user-1/FeelSoNumb'}


- Second call

{'MessageId': '85804907-625a-4a14-9e6c-d392dc93b67c',
 'ReceiptHandle': 'AQEBtbehAmrFrUYLOXIv/m3KT6Z1OMWnzFZ9dwTPbZgGgCJawA6smp+jAVH50ntqCYQSlyQZxJjYIIMtHXlfzfJaMdRiGaJ3Mno79f/Ki/onm0LS/xk0TqWMsoKhzcgiOgINRew/O2xzXxoXduEWAU4H2MYWRuPsQmueBN4htARHPhTnB2AHoMyTXiIezbkqWZQHzfqItzz5RgpzfCdq5PnHq2xupi/2g3RQ9F8USCoW3fDtHcMUzjuSiCerahzUzqLq1ZUKudLjyG08SGumzBAUqA==',
 'MD5OfBody': '37cf7bd444545a12cde89de30728001a',
 'Body': 'user-2/DeathGodOfThunder'}

'''



# Above could benefit from considering message attributes
sqsClient.get_queue_attributes(
    QueueUrl = queueUrl,
    AttributeNames = [ 'Some Attribute' ]
)