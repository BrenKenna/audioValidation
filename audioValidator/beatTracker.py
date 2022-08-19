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

# Plot chromagram
chroma_stft = librosa.feature.chroma_stft(
    y=y,
    sr=sr,
    n_chroma=12, n_fft=4096
)
chroma_cq = librosa.feature.chroma_cqt(y=y, sr=sr)
fig, ax = plt.subplots(nrows=2, sharex=True, sharey=True)
librosa.display.specshow(chroma_stft, y_axis='chroma', x_axis='time', ax=ax[0])
ax[0].set(title='chroma_stft')
ax[0].label_outer()
img = librosa.display.specshow(chroma_cq, y_axis='chroma', x_axis='time', ax=ax[1])
ax[1].set(title='chroma_cqt')
fig.colorbar(img, ax=ax)


