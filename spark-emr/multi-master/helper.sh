

# Reboot all primary nodes once, then test running a step on cluster
sudo reboot -f
yarn rmadmin -getAllServiceState

''' 

ip-192-168-2-157.eu-west-1.compute.internal:8033   active    
ip-192-168-2-15.eu-west-1.compute.internal:8033    standby   
2022-12-30 11:54:04,402 INFO ipc.Client: Retrying connect to server: ip-192-168-2-4.eu-west-1.compute.internal/192.168.2.4:8033. Already tried 0 time(s); retry policy is RetryUpToMaximumCountWithFixedSleep(maxRetries=1, sleepTime=1000 MILLISECONDS)
ip-192-168-2-4.eu-west-1.compute.internal:8033     Failed to connect: Call From ip-192-168-2-157.eu-west-1.compute.internal/192.168.2.157 to ip-192-168-2-4.eu-west-1.compute.internal:8033 failed on connection exception: java.net.ConnectException: Connection refused; For more details see:  http://wiki.apache.org/hadoop/ConnectionRefused


ip-192-168-2-157.eu-west-1.compute.internal:8033   active    
ip-192-168-2-15.eu-west-1.compute.internal:8033    standby   
ip-192-168-2-4.eu-west-1.compute.internal:8033     standby  
'''


# Run single audio validation step: 11 tracks done in ~2.5mins, ~14s a track
aws emr add-steps \
    --region "eu-west-1" \
    --cluster-id "j-2ZZ4M65MSBWJ0" \
    --steps file:///home/ec2-user/audioVal-step.json

aws emr list-steps \
    --region "eu-west-1" \
    --cluster-id "j-2ZZ4M65MSBWJ0" \
    --step-ids "s-2JUEWJJUOJHNT"

'''

- Submits ok, and completed

{
    "StepIds": [
        "s-2JUEWJJUOJHNT"
    ]
}

"Status": {
                "Timeline": {
                    "EndDateTime": 1672401822.09, 
                    "CreationDateTime": 1672401651.471, 
                    "StartDateTime": 1672401667.565
                }, 
                "State": "COMPLETED", 
                "StateChangeReason": {}
            }


'''


# Follow-up on app logs
appDir="s3://bk-spark-cluster-tf/j-2ZZ4M65MSBWJ0/containers/application_1672401347379_0001/"
hdfs dfs -ls ${appDir} | wc -l
hdfs dfs -cat ${appDir}/container_e03_1672401347379_0001_01_000001/stderr.gz | gzip -d - | less

"""

22/12/30 12:01:33 INFO YarnAllocator: Launching container container_e03_1672401347379_0001_01_000002 on host ip-192-168-2-124.eu-west-1.compute.internal for execut
or with ID 1 for ResourceProfile Id 0 with resources <memory:5632, max memory:6144, vCores:1, max vCores:4>
22/12/30 12:01:33 INFO YarnAllocator: Launching executor with 4742m of heap (plus 890m overhead/off heap) and 2 cores
22/12/30 12:01:33 INFO YarnAllocator: Received 1 containers from YARN, launching executors on 1 of them.
22/12/30 12:01:33 INFO ExecutorRunnable: Initializing service data for shuffle service using name 'spark_shuffle'
22/12/30 12:01:35 INFO SparkContext: Starting job: collect at audioValidator-Test.py:42
22/12/30 12:01:35 INFO DAGScheduler: Got job 0 (collect at audioValidator-Test.py:42) with 2 output partitions
22/12/30 12:01:35 INFO DAGScheduler: Final stage: ResultStage 0 (collect at audioValidator-Test.py:42)
22/12/30 12:01:35 INFO DAGScheduler: Parents of final stage: List()
22/12/30 12:01:35 INFO DAGScheduler: Missing parents: List()
22/12/30 12:01:35 INFO DAGScheduler: Submitting ResultStage 0 (PythonRDD[1] at collect at audioValidator-Test.py:42), which has no missing parents
22/12/30 12:01:35 INFO YarnAllocator: Driver requested a total number of 1 executor(s) for resource profile id: 0.
22/12/30 12:01:35 INFO YarnAllocator: Canceling requests for 99 executor container(s) to have a new desired total 1 executors.
22/12/30 12:01:36 INFO MemoryStore: Block broadcast_0 stored as values in memory (estimated size 5.7 KiB, free 1028.8 MiB)
22/12/30 12:01:36 INFO MemoryStore: Block broadcast_0_piece0 stored as bytes in memory (estimated size 3.7 KiB, free 1028.8 MiB)
22/12/30 12:01:36 INFO BlockManagerInfo: Added broadcast_0_piece0 in memory on ip-192-168-2-44.eu-west-1.compute.internal:35139 (size: 3.7 KiB, free: 1028.8 MiB)
22/12/30 12:01:36 INFO SparkContext: Created broadcast 0 from broadcast at DAGScheduler.scala:1570
22/12/30 12:01:36 INFO DAGScheduler: Submitting 2 missing tasks from ResultStage 0 (PythonRDD[1] at collect at audioValidator-Test.py:42) (first 15 tasks are for p
artitions Vector(0, 1))
22/12/30 12:01:36 INFO YarnClusterScheduler: Adding task set 0.0 with 2 tasks resource profile 0

...

22/12/30 12:03:39 INFO YarnClusterScheduler: Killing all running tasks in stage 0: Stage finished
22/12/30 12:03:39 INFO DAGScheduler: Job 0 finished: collect at audioValidator-Test.py:42, took 123.437323 s
22/12/30 12:03:39 INFO YarnAllocator: Driver requested a total number of 0 executor(s) for resource profile id: 0.
22/12/30 12:03:39 INFO ApplicationMaster: Final app status: SUCCEEDED, exitCode: 0
22/12/30 12:03:39 INFO SparkContext: Invoking stop() from shutdown hook
"""

# Follow-up on active master logs
primaryNodeLogs=s"3://bk-spark-cluster-tf/j-2ZZ4M65MSBWJ0/node/i-0b7859fb82a817121"
pnDaemon="${primaryNodeLogs}/daemons"
pnApps="${primaryNodeLogs}/applications"

# Nothing much
hdfs dfs -ls ${pnDaemon}/instance-state/ | grep "2022-12-30-12"
hdfs dfs -cat ${pnDaemon}/instance-state/instance-state.log-2022-12-30-12-00.gz | gzip -d - | less


ws s3 cp s3://bk-spark-cluster-tf/j-2ZZ4M65MSBWJ0/node/i-0b7859fb82a817121/applications/zookeeper/zookeeper-zookeeper-server-ip-192-168-2-15.log.gz ./
aws s3 cp s3://bk-spark-cluster-tf/j-2ZZ4M65MSBWJ0/node/i-0bee9d521b61affcf/applications/zookeeper/zookeeper-zookeeper-server-ip-192-168-2-4.log.gz ./
aws s3 cp s3://bk-spark-cluster-tf/j-2ZZ4M65MSBWJ0/node/i-0bd7948c9a693f555/applications/zookeeper/zookeeper-zookeeper-server-ip-192-168-2-157.log.gz ./

''' --> zookeeper-zookeeper-server-ip-192-168-2-15.log.gz

2022-12-30 11:53:46,673 [myid:1] - WARN  [QuorumConnectionThread-[myid=1]-5:QuorumCnxManager@381] - Cannot open channel to 2 at election address ip-192-168-2-4.eu-
west-1.compute.internal/192.168.2.4:3888
java.net.ConnectException: Connection refused (Connection refused)
        at java.net.PlainSocketImpl.socketConnect(Native Method)
        at java.net.AbstractPlainSocketImpl.doConnect(AbstractPlainSocketImpl.java:350)
        at java.net.AbstractPlainSocketImpl.connectToAddress(AbstractPlainSocketImpl.java:206)
        at java.net.AbstractPlainSocketImpl.connect(AbstractPlainSocketImpl.java:188)
        at java.net.SocksSocketImpl.connect(SocksSocketImpl.java:392)
        at java.net.Socket.connect(Socket.java:607)
        at org.apache.zookeeper.server.quorum.QuorumCnxManager.initiateConnection(QuorumCnxManager.java:373)
        at org.apache.zookeeper.server.quorum.QuorumCnxManager$QuorumConnectionReqThread.run(QuorumCnxManager.java:436)
        at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1149)
        at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:624)
        at java.lang.Thread.run(Thread.java:750)


2022-12-30 11:55:48,924 [myid:1] - ERROR [LearnerHandler-/192.168.2.157:45374:LearnerHandler@629] - Unexpected exception causing shutdown while sock still open
java.net.SocketTimeoutException: Read timed out
2022-12-30 11:55:48,925 [myid:1] - WARN  [LearnerHandler-/192.168.2.157:45374:LearnerHandler@644] - ******* GOODBYE /192.168.2.157:45374 ********



---> zookeeper-zookeeper-server-ip-192-168-2-4.log.gz

2022-12-30 11:23:14,123 [myid:2] - WARN  [QuorumConnectionThread-[myid=2]-1:QuorumCnxManager@381] - Cannot open channel to 0 at election address ip-192-168-2-157.e
u-west-1.compute.internal/192.168.2.157:3888
java.net.ConnectException: Connection refused (Connection refused)
2022-12-30 11:23:14,123 [myid:2] - WARN  [QuorumConnectionThread-[myid=2]-2:QuorumCnxManager@381] - Cannot open channel to 1 at election address ip-192-168-2-15.eu
-west-1.compute.internal/192.168.2.15:3888
java.net.ConnectException: Connection refused (Connection refused)
2022-12-30 11:23:14,324 [myid:2] - INFO  [QuorumPeer[myid=2](plain=[0:0:0:0:0:0:0:0]:2181)(secure=disabled):FastLeaderElection@937] - Notification time out: 400
2022-12-30 11:23:14,324 [myid:2] - WARN  [QuorumConnectionThread-[myid=2]-2:QuorumCnxManager@381] - Cannot open channel to 1 at election address ip-192-168-2-15.eu
-west-1.compute.internal/192.168.2.15:3888
2022-12-30 11:23:14,324 [myid:2] - WARN  [QuorumConnectionThread-[myid=2]-3:QuorumCnxManager@381] - Cannot open channel to 0 at election address ip-192-168-2-157.e
u-west-1.compute.internal/192.168.2.157:3888
java.net.ConnectException: Connection refused (Connection refused)


2022-12-30 11:40:28,561 [myid:2] - ERROR [LearnerHandler-/192.168.2.15:42592:LearnerHandler@629] - Unexpected exception causing shutdown while sock still open
java.net.SocketTimeoutException: Read timed out
2022-12-30 11:40:28,562 [myid:2] - WARN  [LearnerHandler-/192.168.2.15:42592:LearnerHandler@644] - ******* GOODBYE /192.168.2.15:42592 ********
2022-12-30 11:40:30,396 [myid:2] - INFO  [SessionTracker:ZooKeeperServer@437] - Expiring session 0x3925a0001, timeout of 10000ms exceeded
2022-12-30 11:40:30,396 [myid:2] - INFO  [SessionTracker:QuorumZooKeeperServer@157] - Submitting global closeSession request for session 0x3925a0001
2022-12-30 11:40:35,085 [myid:2] - INFO  [ip-192-168-2-4.eu-west-1.compute.internal/192.168.2.4:3888:QuorumCnxManager$Listener@937] - Received connection request f
rom /192.168.2.15:42208
2022-12-30 11:40:35,086 [myid:2] - WARN  [SendWorker:1:QuorumCnxManager$SendWorker@1156] - Interrupted while waiting for message on queue
java.lang.InterruptedException

2022-12-30 11:55:57,564 [myid:2] - INFO  [ip-192-168-2-4.eu-west-1.compute.internal/192.168.2.4:3888:QuorumCnxManager$Listener@937] - Received connection request f
rom /192.168.2.157:56042
2022-12-30 11:55:57,568 [myid:2] - WARN  [RecvWorker:0:QuorumCnxManager$RecvWorker@1242] - Connection broken for id 0, my id = 2, error = 
java.net.SocketException: Socket closed


---> 
'''
