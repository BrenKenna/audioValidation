# -*- coding: utf-8 -*-
"""
Created on Wed Sep 21 13:46:20 2022

@author: kenna
"""

# Import required modules
import os, sys
import boto3
import json


# Class to support creating queues
class QueueManager():
    
    # Class attributes
    def __init__(self, queueName):
        self.queueName = str(queueName + '.fifo')
        self.sqsClient = boto3.client('sqs')
        self.sqsResource = boto3.resource('sqs')
        self.queue = None
        
    
    # Create queue
    def createQueue(self, delaySec = 10, timeout = 60):
        self.queue = self.sqsClient.create_queue(
            QueueName = self.queueName,
            Attributes = {
                'DelaySeconds': str(10),
                'FifoQueue': 'true',
                'VisibilityTimeout': str(timeout)
            }
        )
    
    
    # Update queue name
    def setQueueName(self, newName, createQueue = False):
        
        # Update queue name
        self.queueName = str(newName + '.fifo')
        
        # Handle creating queue with new name
        if createQueue == True:
            self.createQueue()

    
    # Get queue
    def getQueue(self):
        self.queue = self.sqsClient.get_queue_url(QueueName = self.queueName)
        
    
    # Delete queue
    def deleteQueue(self):
        return self.sqsClient.delete_queue(QueueUrl = self.queueName)


    # Send message
    def sendMsg(self, data):
        if type(data) != tuple:
            print('Error, expected tuple')
            return []
        
        # Create post args
        partitionKey = str(data[0] + "/" + data[1])
        msgAttributes = {
            'UserID': {
                'StringValue': data[0],
                'DataType': 'String'
            },
            'TrackName': {
                'StringValue': data[1],
                'DataType': 'String'
            },
            'TrackPath': {
                'StringValue': data[2],
                'DataType': 'String'
            }
        }
        
        # Post message
        response = self.sqsClient.send_message(
            QueueUrl = self.queue['QueueUrl'],
            MessageBody = partitionKey,
            MessageGroupId = data[0],
            MessageDeduplicationId = partitionKey,
            MessageAttributes = msgAttributes
        )
        return response
    
    
    # Send messages
    def sendMessages(self, dataset):
        output = []
        for data in dataset:
            output.append(self.sendMsg(data))
        return output


    # Get message
    def getMsg(self):
        response = self.sqsClient.receive_message(QueueUrl = self.queue['QueueUrl'])
        if 'Messages' in response:
            return response['Messages'][0]
        return None

    # Delete message
    def deleteMsg(self, message):
        if 'ReceiptHandle' in message:
            self.sqsClient.delete_message(
                QueueUrl = self.queue['QueueUrl'],
                ReceiptHandle = message['ReceiptHandle']
            )

    # Poll message
    def pollMsg(self):
        message = self.getMsg()
        if message != None:
            self.deleteMsg(message)
        return message