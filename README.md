# audioValidation



## Overview

Exploring an EMR supported audio validation system using the Librosa & SoundFile packages. The main elements being explored are how to classify a mock audio signal vs a real audio signal by using "***audio fingerprinting***". Then how to deliver data into this system preferencing the idea that data streaming can act as a funnel before that data touches storage.



The context is a paranoid & fun one to learn more about AWS's big data solutions from a continous computing perspective, over a batch computing perspective (like with my work on ***PyAnamo***). Longterm the system can be deployed alongside bandCloud. Allowing the application to validate the audio data it recieves and then take action based on the results in real-time. So that the bandCloud service isn't a glorified malware storage system, with audio data being the vector :).



[GitHub - BrenKenna/bandCloud: A pointer repo to the complete code for the bandCloud app](https://github.com/BrenKenna/bandCloud.git)



## Current State

### Overview

Overall the project is in a very nice position with an example classifier that can be map reducable, and has a working kinesis stream producer & consumer for sharding & rebuilding a compressed audio signal. So some of the hardest parts have been done first. Few more to tackle as the below summary points highlight.



As per the below, the next steps are around putting a queue to consuming data stream, then passing the rebuilt audio signal to the audioValidator. Which will mean I have two ways of using the spark cluster, one from putting a collection of files on S3 and the second from consuming the audio filtration system (Kinesis Stream). Which overtime could look at what the likes Kafka & serverless options offer an app like this.



With the queue done, comeback to EMR bootsrapping headaches. Then see where things lie there, in general and the notion of auto-scaling kinesis streams.



### Summary Points

1. In general its being quite nice to touch base with python again from now knowing what SOLID is lol :). Like, dynamic typing is pretty handy for sniffing things out before packaging things up, which helps separate the core things that are needed from the nice things. That to a certain degree, lets things grow more naturally, i.e "***seeing the forest through the trees***". Also got a few notes for bandCloud, but that's a "***sin scéal eile***".
   
   

2. Packaged up the tested & debugged audioValidator and streamer modules with their respective data. Tried to make use of the "***init.py***" and "***importlib.resources***" module where I can. But still kind of new to that, like it very much all the same.
   
   

3. Need to consider baseline objects that are commonly encountered:
   
   1. Audio with the wave, sample rate and track lengths
   
   2. Audio descriptor with track name and path
   
   3. The need for audioStream consumer to instantiate the audioValidator from a rebuilt audio signal. Thinking an object that can created from file or Audio model class.
      
      

4. Going to look at putting a queue around consuming the data within a stream. The current partition key is "***userID/Track Name***". Allowing an element in that queue to be the string that the consumer evaluates per rebuild. The consumer could then poll a handful of these if needs be.
   
   

5. Given how bandCloud is deployed into multiple AZs, considering the idea that each AZ can have a number of baseline streams that they write to. Where additional streams can be created & destroyed to handle increased traffic to bandCloud. The rational is to better optimize the use of streams in terms of cost & performance, because distributing the consumption across streams lowers the number of gzipped compressed track shards per stream.
