# -*- coding: utf-8 -*-
"""
Created on Sun Aug 21 17:55:42 2022

@author: kenna
"""


# Import required modules
import os, sys
import librosa
import librosa.display
import numpy as np
import json
import matplotlib.pyplot as plt
import pandas as pd
from sklearn.svm import SVC

# Import resources
from importlib import resources

# 
# Class to handle classification
#   => Could maybe offer a little more simple things?
#       -> How different an unseen row is to training etc
#       -> Shaping functions because json -> pd -> np
#
# Also why I wish python was typed :(
# 
class AudioValComparator():
    
    def __init__(self):
        
        # Attributes for training
        self.training = "summaries.json"
        self.data = None
        self.train = None
        self.labels = None
        self.svm = SVC()
        
        # Columns to drop
        self.colsDrop = [
          "Label",
          "Track",
          "Track Name",
          "Length seconds",
          "Wave Size",
          "Sampling Rate",
          "Played Size",
          "Not Played Sum"
        ]
        
        # Training cols
        self.trainingCols = [
            "Mean Played/s",
            "Mean Not Played/s",
            "Played Sum",
            "Tempo",
            "File Size MB",
            "MB / s",
            "Notes / Tempo"
        ]
        
        # Attribute to hold its work?
        # self.results = []
    
    
    # Read generator resource
    def readResource(self):
        with resources.open_text("audioValidator.comparator.data", self.training) as file:
            data = json.load(file)
        file.close()
        return data
    
    
    # Load training data
    def loadTrainingSet(self):
        self.data = pd.DataFrame(self.readResource())
        self.labels = self.data.Label
        self.train = self.data.drop(self.colsDrop, axis = 1)


    # Set model state
    def setState(self):
        
        # Build model
        self.svm.fit(self.train, self.labels)

        # Set fields on self
        self.data['Prediction'] = self.svm.predict(self.train).tolist()
        self.data["Pred State"] = self.data["Label"] == self.data["Prediction"]
        
    
    # Get model state
    def getState(self):
        return self.data[ [ "Track", "Label", "Prediction", "Pred State" ] ]
    
    
    # Assign label
    def compareRow(self, row, assignToDF = False):
        
        # Check cols first
        output = None
        anaRow = row[ self.trainingCols ]
        # if set(self.trainingCols).issubset(row.columns):
        if 0 == 0:
            output = self.svm.predict(anaRow)[0]
        
        # Otherwise pass
        #  should really raise an exception (3rd time now for whole program)
        else:
            output = "INVALID INPUT DATA"

        # Return results
        if assignToDF:
            row["Label"] = output
        return output


    # Map input results to a valid row
    def mapResults(self, results):
        output = pd.DataFrame.from_dict(results, orient='index').transpose()
        colsDrop = [
                "Track",
                "Track Name",
                "Length seconds",
                "Wave Size",
                "Sampling Rate",
                "Played Size",
                "Not Played Sum"
        ]
        output = output.drop(colsDrop, axis = 1)
        return output