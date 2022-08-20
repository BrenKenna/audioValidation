#############################################
#
#
# Source:
#  https://raw.githubusercontent.com/vxunderground/MalwareSourceCode/main/Java/Virus.Java.Cheshire.a/src/main/java/SelfExamine.java
# 
#############################################

# import modules
import librosa
import librosa.display
import numpy as np
import matplotlib.pyplot as plt


# Read data
with open("generator/goat-java.txt", "r") as f:
    data = f.readlines()
f.close()

# N records = 70k
# Sampling rate ~ 100
# Usually sampling rate is the size of the complete signal
#  - See if you can beat track
mockSignal = [ ]
for line in data:
    for char in line.replace('\n', ''):
        mockSignal.append(float(ord(char)))

# Revert
chars = []
for i in mockSignal:
    chars.append(chr(int(i)))

# Join
''.join(chars)



###################################


# Try track a beat
tempo, beat_frames = librosa.beat.beat_track(
    y = np.asarray(mockSignal),
    sr = 2000
)

'''
>>> tempo
234.375

>>> beat_frames.shape
(134,)

'''

# Try chromagram
chroma_mal = librosa.feature.chroma_stft(
    y = np.asarray(mockSignal),
    sr = 2000,
    n_chroma=12,
    n_fft=1000
)
img = librosa.display.specshow(chroma_stft, y_axis='chroma', x_axis='time')

'''
70014, @ 2000
    => Duration = 70014/200 = 35 

chroma_mal.shape
Out[22]: (12, 137)

'''