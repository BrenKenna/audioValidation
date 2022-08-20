'''

- Look at the chromagram and set hard filters
    => What range based metrics can be calculated from the results?
        - Start with note so you can measure frequency of each note,
            leads on average a song has this collection

harmonic-percussive separation, multiple spectral features, and beat-synchronous feature aggregation
    => Comeback to plotting

https://librosa.org/doc/latest/tutorial.html


- Sir Duke chroma representation - Fast and slow
    => Is there a predominant pitch

https://librosa.org/doc/latest/auto_examples/plot_music_sync.html#sphx-glr-auto-examples-plot-music-sync-py


- Chromagram

https://librosa.org/doc/latest/generated/librosa.feature.chroma_cqt.html#librosa.feature.chroma_cqt

'''

# Beat tracking example
import librosa
import librosa.display
import numpy as np
import matplotlib.pyplot as plt
import json


# 1. Get the file path to an included audio example
filename = librosa.example('nutcracker')


# 2. Load the audio as a waveform `y`
#    Store the sampling rate as `sr`
y, sr = librosa.load(filename)


'''

- Grounds for an object with common np-array helper methods

(y.shape[0] / sr) / 60
120
1.9979319727891156


'''

# Run the default beat tracker &
# convert the frame indices of beat events into timestamps
tempo, beat_frames = librosa.beat.beat_track(y=y, sr=sr)
beat_times = librosa.frames_to_time(beat_frames, sr=sr)
print('Estimated tempo: {:.2f} beats per minute'.format(tempo))


'''

The output of the beat tracker is an estimate of the tempo (in beats per minute), and an array of frame numbers corresponding to detected beat events.

beat_frames.shape
(212,)

(212,)

'''


#########################################
# 
# Tonal and Percussion Separation
# 
#########################################


'''

is two-fold: first, percussive elements tend to be stronger indicators of rhythmic content, and can help provide more stable beat tracking results; second, percussive elements can pollute tonal feature representations (such as chroma) by contributing energy across all frequency bands, so we’d be better off without them


- Audio data is massive, but a collection of frames within a clip may not change
 much. Condense a small feature set into a datapoint 

http://practicalcryptography.com/miscellaneous/machine-learning/guide-mel-frequency-cepstral-coefficients-mfccs/


- Chromogram with pitches
https://librosa.org/doc/latest/generated/librosa.feature.chroma_cqt.html#librosa.feature.chroma_cqt

'''


# Set the hop length; at 22050 Hz, 512 samples ~= 23ms
hop_length = 512

# Separate harmonics and percussives into two waveforms
y_harmonic, y_percussive = librosa.effects.hpss(y)
tempoPerc, beat_framesPerc = librosa.beat.beat_track(
    y=y_percussive,
    sr=sr
)

'''

- Separate the harmonic & percussion signals

- Track the percussion signal because it indicates rythm

'''

# Compute MFCC features from the raw signal,
# and the first-order differences (delta features)
mfcc = librosa.feature.mfcc(y=y, sr=sr, hop_length=hop_length, n_mfcc=13)
mfcc_delta = librosa.feature.delta(mfcc)


# Stack and synchronize between beat events
# This time, we'll use the mean value (default) instead of median
beatPerc_mfcc_delta = librosa.util.sync(
    np.vstack([mfcc, mfcc_delta]),
    beat_framesPerc
)




# Compute chroma features from the harmonic signal
chromagram = librosa.feature.chroma_cqt(
    y=y_harmonic,
    sr=sr
)


# Aggregate chroma features between beat events
# We'll use the median value of each feature between beat frames
beat_chroma = librosa.util.sync(
    chromagram,
    beat_framesPerc,
    aggregate=np.median
)


# Finally, stack all beat-synchronous features together
beat_features = np.vstack([beat_chroma, beatPerc_mfcc_delta])


# Plot results
plt.scatter(beat_features[0].tolist(), beat_features[1].tolist()) 
plt.show()
plt.savefig('beat-features.png')



##########################################
##########################################
# 
# Chromagrams
# 
##########################################
##########################################


# Plot chromagram
chroma_stft = librosa.feature.chroma_stft(
    y=y,
    sr=sr,
    n_chroma=12,
    n_fft=4096
)
chroma_cq = librosa.feature.chroma_cqt(y=y, sr=sr)
fig, ax = plt.subplots(nrows=2, sharex=True, sharey=True)
librosa.display.specshow(chroma_stft, y_axis='chroma', x_axis='time', ax=ax[0])
ax[0].set(title='chroma_stft')
ax[0].label_outer()
img = librosa.display.specshow(chroma_cq, y_axis='chroma', x_axis='time', ax=ax[1])
ax[1].set(title='chroma_cqt')
fig.colorbar(img, ax=ax)



#########################
# 
# Towards Summarizing
# 
#########################


# Import modules
import librosa
import librosa.display
import numpy as np
import matplotlib.pyplot as plt


# Config
filename = librosa.example('nutcracker')
y, sr = librosa.load(filename)
audio_chroma = librosa.feature.chroma_cqt(y=y, sr=sr)


# Dimensions: 43 = 1s, 22 = 0.5
y.shape
audio_chroma.shape

'''
2mins of audio = 120s
    => (5163 / 120) = 43
    => (5163 / 43.025) = 120

Out[4]: (12, 5163)

Out[2]: (2643264,) @ 22050
    => time = 2643264/22050 = 120s
    

( 2643264/22050 ) == 5163 / (5163 / ( 2643264/22050 ) )
Out[42]: True


len(mockSignal)
70014 / 2000, 35
    137 / 35 = 4 # 3.91

'''


# Work with slices
results_mal =  [ [ ] for rows in range(chroma_mal.shape[0]) ]
strt = 0
end = 2
step = 2
chroma_mal.shape[1]
while end < (chroma_mal.shape[1] + 1):
    iters = 0
    pitchCounter = 0
    for pitch in chroma_mal:
        pitchSlice = pitch[strt:end]
        for elm in range(0, len(pitchSlice)):
            if pitchSlice[elm] < 0.8:
                pitchSlice[elm] = 0
            else:
                pitchSlice[elm] = 1
        results_mal[pitchCounter].append( float(np.sum(pitchSlice)/len(pitchSlice)) )
        pitchCounter+=1
    pitchCounter = 0
    iters+=1
    strt = (end+1)
    end = (end + step)


# Convert to nummpy array
results_mal = np.asarray(results_mal).astype('float32')
for i in range(0, 12):
    print(results_mal[i][2])


# Can still create (handy while own is figured out)
results_mal = np.asarray(results_mal).astype('float32')
librosa.display.specshow(results_mal, y_axis='chroma', x_axis='time')



######################################
######################################
# 
# Summaries are interesting
#  metal will obviously break it
# Trying to reflect how busy it is
# 
######################################
######################################


playedSum_mal = 0
nullSum_mal = 0
notesPlayed_mal = []
for i in range(0, results_mal.shape[1]):
    rangeCount = 0
    nullOthers = 0
    for pitch in range(0, 12):
        if results_mal[pitch][i] >= 0.5:
            rangeCount+=1
            playedSum_mal+=1
        else:
            nullOthers+=1
            nullSum_mal+=1
    data = tuple( ( rangeCount, nullOthers ) )
    notesPlayed_mal.append(data)
        


playedSum = 0
nullSum = 0
notesPlayed = []
for i in range(0, results.shape[1]):
    rangeCount = 0
    nullOthers = 0
    for pitch in range(0, 12):
        if results[pitch][i] >= 0.5:
            rangeCount+=1
            playedSum+=1
        else:
            nullOthers+=1
            nullSum+=1
    data = tuple( ( rangeCount, nullOthers ) )
    notesPlayed.append(data)
  


# Summarize
playedSum
playedSum_mal
nullSum
nullSum_mal

playedSum / len(notesPlayed)
playedSum_mal / len(notesPlayed_mal)


nullSum / len(notesPlayed)
nullSum_mal / len(notesPlayed_mal)

'''

Played: 119 vs 249

Null: 1245 vs 567

Average Played: 0.975 vs 3.661

Average Not Played: 11 vs 8

Tempo comparision: 107 vs 234

'''


# Stored info
song = {
    "ID": "dance of sugar plum faeries",
    "Mean Played/ half-s": playedSum / len(notesPlayed),
    "Mean Not Played/ half-s": nullSum / len(notesPlayed),
    "Played Sum": playedSum,
    "Not Played Sum": nullSum,
    "Played Size": len(notesPlayed),
    "Length seconds": y.shape[0]/sr,
    "Tempo": 107,
    "Wave Size": y.shape[0],
    "Sampling Rate": sr
}
malware = {
    "ID": "goat malware",
    "Mean Played/ half-s": playedSum_mal / len(notesPlayed_mal),
    "Mean Not Played/ half-s": nullSum_mal / len(notesPlayed_mal),
    "Played Sum": playedSum_mal,
    "Not Played Sum": nullSum_mal,
    "Played Size": len(notesPlayed_mal),
    "Length seconds": 70014 / 2000,
    "Tempo": 234,
    "Wave Size": 70014,
    "Sampling Rate": 2000
}



# Dump info
jsonDump = [
    song,
    malware
]
print(json.dumps(jsonDump, indent = 2))





######################################
######################################
# 
# Read / Write Audio
# 
######################################
######################################


# Import from sound file
import soundfile as sf


# Write wav: sounds fine
sf.write(
    'nutcracker.wav',
    y,
    sr
)

# No sound
sf.write(
    'malware.wav',
    np.asarray(mockSignal),
    2000
)


# Read some disco
y, sr = librosa.load('examples/Sir-Duke.wav', duration = 120)

tempo, beat_frames = librosa.beat.beat_track(y=y, sr=sr)
y_harmonic, y_percussive = librosa.effects.hpss(y)
chromagram = librosa.feature.chroma_cqt(y=y_harmonic, sr=sr)
librosa.display.specshow(chromagram, y_axis='chroma', x_axis='time')

beat_chroma = librosa.util.sync(
    chromagram,
    beat_framesPerc,
    aggregate=np.median
)
librosa.display.specshow(chromagram, y_axis='chroma', x_axis='time')

plt.show()



# Work with slices
# y.shape[0] / sr = 120
# 5168 / 120 = 43
results_stomp =  [ [ ] for rows in range(chromagram.shape[0]) ]
strt = 0
end = 43
step = 43
chromagram.shape[1]
while end < (chromagram.shape[1] + 1):
    iters = 0
    pitchCounter = 0
    for pitch in chromagram:
        pitchSlice = pitch[strt:end]
        for elm in range(0, len(pitchSlice)):
            if pitchSlice[elm] < 0.8:
                pitchSlice[elm] = 0
            else:
                pitchSlice[elm] = 1
        results_stomp[pitchCounter].append( float(np.sum(pitchSlice)/len(pitchSlice)) )
        pitchCounter+=1
    pitchCounter = 0
    iters+=1
    strt = (end+1)
    end = (end + step)


# Convert to nummpy array
results_stomp = np.asarray(results_stomp).astype('float32')
for i in range(0, 12):
    print(results_stomp[i][2])


# Can still create (handy while own is figured out)
#results_mal = np.asarray(results_mal).astype('float32')
librosa.display.specshow(results_stomp, y_axis='chroma', x_axis='time')

playedSum_metal = 0
nullSum_metal = 0
notesPlayed_metal = []
for i in range(0, results_stomp.shape[1]):
    rangeCount = 0
    nullOthers = 0
    for pitch in range(0, 12):
        if results_stomp[pitch][i] >= 0.5:
            rangeCount+=1
            playedSum_metal+=1
        else:
            nullOthers+=1
            nullSum_metal+=1
    data = tuple( ( rangeCount, nullOthers ) )
    notesPlayed_metal.append(data)
 

sir_du = {
    "ID": "stomp",
    "Mean Played/ half-s": playedSum_metal / len(notesPlayed_metal),
    "Mean Not Played/ half-s": nullSum_metal / len(notesPlayed_metal),
    "Played Sum": playedSum_metal,
    "Not Played Sum": nullSum_metal,
    "Played Size": len(notesPlayed_metal),
    "Length seconds": y.shape[0] / sr,
    "Tempo": tempo,
    "Wave Size": y.shape[0],
    "Sampling Rate": sr
}



# Dump info
jsonDump = [
    song,
    stomp,
    disco,
    metal,
    blackMetal,
    malware
]
print(json.dumps(jsonDump, indent = 2))

# Directly from dictionary
with open('chromagram-summaries.json', 'w') as outfile:
    json.dump(jsonDump, outfile)



with open('chromagram-summaries.json') as json_file:
    data = json.load(json_file)
    print(data)