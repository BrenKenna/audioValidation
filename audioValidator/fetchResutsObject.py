# -*- coding: utf-8 -*-
"""
Created on Sat Aug 20 18:51:44 2022

@author: kenna
"""


# Import required modules
import os, sys
import librosa
import librosa.display
import numpy as np
import json
import matplotlib.pyplot as plt

from results import results


#################################
# 
# Track analysis
# 
#################################


# Load track
sirDuke = results.AudioValResult('Thorns Crim. Death', 'examples/Thorns-of-Crimson-Death.wav')


# Librosa analysis
sirDuke.percusHarmonSep()
sirDuke.generateChromagram()
sirDuke.setTempo()


# Analyze above results
sirDuke.initializeChromAna() # halfSec = False
'''

(0, 43, 43)

'''

sirDuke.analyzeChroma()


# Summarize
sirDuke.summarizePitchFreq()
sirDuke.setResults()

'''

(105, 1335)

'''


# Print results
print(json.dumps([sirDuke.results], indent = 2))

'''

[
  {
    "Track": "Sir Duke",
    "Track Name": "examples/Sir-Duke.wav",
    "Mean Played/s": 0.875,
    "Mean Not Played/s": 11.125,
    "Played Sum": 105,
    "Not Played Sum": 1335,
    "Played Size": 120,
    "Length seconds": 120,
    "Tempo": 107.666015625,
    "Wave Size": 2646000,
    "Sampling Rate": 22050
  },

  {
    "Track": "Thorns Crim. Death",
    "Track Name": "examples/Thorns-of-Crimson-Death.wav",
    "Mean Played/s": 1.1833333333333333,
    "Mean Not Played/s": 10.816666666666666,
    "Played Sum": 142,
    "Not Played Sum": 1298,
    "Played Size": 120,
    "Length seconds": 120,
    "Tempo": 143.5546875,
    "Wave Size": 2646000,
    "Sampling Rate": 22050
  }
]

'''



#################################
# 
# Track generating
#  10 '_'
# 
#################################


# Import
from generator import generator

# Generate audio signal
goatMal = generator.AudioValGenerator('Half-Compendium', 'generator/half-compendium.txt')
goatMal.generateSignal()
goatMal.audioSignal.shape
goatMal.sampleRate

# Export to wav: (1102262, 11022)
goatMal.exportWav('generator/half-compendium.wav')


# Read and analyze
goatAna = results.AudioValResult('Goat', 'generator/goat-java.wav')
goatAna.percusHarmonSep()
goatAna.generateChromagram()
goatAna.setTempo()


# Analyze chromagram
goatAna.initializeChromAna() # halfSec = False
goatAna.analyzeChroma()


# Summarize results
goatAna.summarizePitchFreq()
goatAna.setResults()
print(json.dumps([goatAna.results], indent = 2))


'''

- Collection only doable with >7M lines of code

[
  {
    "Track": "Goat",
    "Track Name": "generator/goat-java.wav",
    "Mean Played/s": 3.2,
    "Mean Not Played/s": 8.8,
    "Played Sum": 112,
    "Not Played Sum": 308,
    "Played Size": 35,
    "Length seconds": 35,
    "Tempo": 0,
    "Wave Size": 771905,
    "Sampling Rate": 22050
  },
  
  {
    "Track": "Collection",
    "Track Name": "generator/collection-java.wav",
    "Mean Played/s": 1.32,
    "Mean Not Played/s": 10.68,
    "Played Sum": 132,
    "Not Played Sum": 1068,
    "Played Size": 100,
    "Length seconds": 100,
    "Tempo": 0,
    "Wave Size": 2205001,
    "Sampling Rate": 22050
  }
]

'''


#######################
# 
# Build Collection
# 
#######################


# Import required modules
import os, sys
import librosa
import librosa.display
import numpy as np
import json
import matplotlib.pyplot as plt

from results import results


# Setup analysis
output = [ ]
toDo = [
   ('Goat', 'generator/goat-java.wav', 1),
   ('Collection', 'generator/collection-java.wav', 1),
   ('Half-Compendium', 'generator/half-compendium.wav', 1),
   ('Compendium', 'generator/compendium.wav', 1),
   ('Wihing Well', 'examples/Wishing-Well.wav', 0),
   ('Stomp', 'examples/Stomp.wav', 0),
   ('Beat Goes on', 'examples/And-the-Beat-Goes-On.wav', 0),
   ('Sir Duke', 'examples/Sir-Duke.wav', 0),
   ('Wihing Well', 'examples/Wishing-Well.wav', 0),
   ('Give Me the Night', 'examples/Give-Me-The-Night.wav', 0),
   ('Thorns of Crimson Death', 'examples/Thorns-of-Crimson-Death.wav', 0)
]


# Run
for track in toDo:
    trackAna = results.AudioValResult(track[0], track[1], track[2])
    trackAna.percusHarmonSep()
    trackAna.generateChromagram()
    trackAna.setTempo()
    trackAna.initializeChromAna() # halfSec = False
    trackAna.analyzeChroma()
    trackAna.summarizePitchFreq()
    trackAna.setResults()
    output.append(trackAna.results)
    del trackAna


# Pretty print results
print(json.dumps(
    output,
    indent = 2
))


# Dump
with open('summaries.json', 'w') as outfile:
    json.dump(output, outfile)


'''

- Sums are still quite different

(0, 43, 43)
(112, 308)
(0, 43, 43)
(132, 1068)

(0, 43, 43)
(132, 1308)
(0, 43, 43)
(125, 1315)
(0, 43, 43)
(111, 1329)
(0, 43, 43)
(105, 1335)
(0, 43, 43)
(132, 1308)
(0, 43, 43)
(113, 1327)
(0, 43, 43)
(142, 1298)

'''


#####################################
#####################################
# 
# Building Comparator
# 
# 1. Build model from training
# 2. Build result from new example
# 3. Fetch as pd row
# 4. Fit model to this row
# 
#####################################
#####################################


# Import required modules
import os, sys
import librosa
import librosa.display
import numpy as np
import json
import matplotlib.pyplot as plt


# Pandas & SVM
import pandas as pd
from sklearn.svm import SVC
from sklearn.metrics import accuracy_score


# Audio validator
from results import results
from generator import generator


# Read & train model
training = "summaries.json"
data = pd.io.json.read_json(training)



# Configure for training; df.to_numpy()
svm = SVC()
labels = data.Label
train = data.drop(
    [
      "Label",
      "Track",
      "Track Name",
      "Length seconds",
      "Wave Size",
      "Sampling Rate",
      "Played Size",
      "Not Played Sum"
    ],
    axis=1
) # Search col space, 0 = row

svm.fit(train, labels)



# Predict self
data['Prediction'] = svm.predict(train).tolist()
data["Pred State"] = data["Label"] == data["Prediction"]
data[ [ "Track", "Label", "Prediction", "Pred State" ] ] 


'''

- Tempo plus metrics not enough to salvage the extreme and unlikely case

                     Track  Label  Prediction  Pred State
0                     Goat      1           1        True
1               Collection      1           0       False
2              Wihing Well      0           0        True
3                    Stomp      0           0        True
4             Beat Goes on      0           0        True
5                 Sir Duke      0           0        True
6              Wihing Well      0           0        True
7        Give Me the Night      0           0        True
8  Thorns of Crimson Death      0           0        True



- Better performance with below columns


Index(['Mean Played/s', 'Mean Not Played/s', 'Played Sum', 'Tempo',
       'File Size MB', 'MB / s', 'Notes / Tempo'],
      dtype='object')


                      Track  Label  Prediction  Pred State
0                      Goat      1           1        True
1                Collection      1           1        True
2           Half-Compendium      1           1        True
3                Compendium      1           1        True
4               Wihing Well      0           0        True
5                     Stomp      0           0        True
6              Beat Goes on      0           0        True
7                  Sir Duke      0           0        True
8               Wihing Well      0           0        True
9         Give Me the Night      0           0        True
10  Thorns of Crimson Death      0           0        True


'''



###################
###################
# 
# Tying Together
# 
###################
###################


# Import required modules
import os, sys
import librosa
import librosa.display
import numpy as np
import json
import matplotlib.pyplot as plt
import pandas as pd

from results import results


# Setup analysis
output = [ ]
toDo = [
   ('Fell So Numb', 'examples/test/Feel-So-Numb.wav'),
   ('Death - God of Thunder', 'examples/test/God-of-Thunder.wav'),
   ('Melechesh-1', 'examples/test/Grand-Gathas-of-Baal-Sin.wav'),
   ('Superbeast', 'examples/test/Superbeast.wav'),
   ('Melechesh-2', 'examples/test/Tempest-Temper-Enlil-Enraged.wav')
]


# Run
for track in toDo:
    trackAna = results.AudioValResult(track[0], track[1])
    trackAna.percusHarmonSep()
    trackAna.generateChromagram()
    trackAna.setTempo()
    trackAna.initializeChromAna() # halfSec = False
    trackAna.analyzeChroma()
    trackAna.summarizePitchFreq()
    trackAna.setResults()
    output.append(trackAna.getResultsAsRow())
    del trackAna


# 
colsDrop = [
    "Track",
    "Track Name",
    "Length seconds",
    "Wave Size",
    "Sampling Rate",
    "Played Size",
    "Not Played Sum"
]

for testCase in output:
    test = testCase.drop( colsDrop, axis = 1)
    print(testCase["Track"][0] + " = " + str(svm.predict(test)[0]))


'''

- Death, Skank & Black metal tests worked out ok

Fell So Numb = 0
Death - God of Thunder = 0
Melechesh-1 = 0
Superbeast = 0
Melechesh-2 = 0
Melechesh-2 = 0

'''



###################################
###################################
# 
# Scope out comparator
# 
###################################
###################################



# Import required modules
import os, sys
import librosa
import librosa.display
import numpy as np
import json
import matplotlib.pyplot as plt
import pandas as pd


# Audio validator shtuff
from generator import generator
from results import results
from comparator import comparator


# Instantiate & load model
audioVal = comparator.AudioValComparator()
audioVal.loadTrainingSet()
audioVal.setState()
audioVal.getState()


'''


                      Track  Label  Prediction  Pred State
0                      Goat      1           1        True
1                Collection      1           1        True
2           Half-Compendium      1           1        True
3                Compendium      1           1        True
4               Wihing Well      0           0        True
5                     Stomp      0           0        True
6              Beat Goes on      0           0        True
7                  Sir Duke      0           0        True
8               Wihing Well      0           0        True
9         Give Me the Night      0           0        True
10  Thorns of Crimson Death      0           0        True


'''


# Trial a track
track = ('Melechesh-2', 'examples/test/Tempest-Temper-Enlil-Enraged.wav')
trackAna = results.AudioValResult(track[0], track[1])
trackAna.percusHarmonSep()
trackAna.generateChromagram()
trackAna.setTempo()
trackAna.analyzeChroma()
trackAna.setResults()


# For testing all methods
outputA = trackAna.getResultsAsRow()
outputB = trackAna.getResultsAsRow(filter = True)
audioVal.compareRow(outputB, assignToDF = True)



################################
################################
# 
# Test scripts
# 
################################
################################


# Generate audio signal
python run-generator.py -m "generator\goat-java.txt" -n "Goat Java"


# Generate results
python run-results-maker.py -s "examples\test\Tempest-Temper-Enlil-Enraged.wav" -n "Melechesh"


# Generate classification
python run-comparator.py -s "examples\test\Tempest-Temper-Enlil-Enraged.wav" -n "Melechesh"