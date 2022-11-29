#!/bin/bash


# App repo
APP_REPO="986224559876.dkr.ecr.eu-west-1.amazonaws.com/audio-validation"
sudo yum install -y docker
sudo service docker start
sudo usermod -a -G docker hadoop


# Configure audioVal img
mkdir audioVal-Docker && cd audioVal-Docker
$(aws ecr get-login-password --region "eu-west-1" |\
    docker login --username AWS -p "${ECR_PASS}" "${APP_REPO}" )

sudo docker build --no-cache -t audio-validator .
sudo docker tag audio-validator:latest ${APP_REPO}:latest
sudo docker push ${APP_REPO}:latest


# Debug build errors if needs be
sudo docker run -it audio-validator

'''

- Build worked fine

usage: run-comparator.py [-h] [-s SIGNAL] [-n NAME] [-o OUTPATH]

Use summary statistics from audio finger printing to decern text or audio.

optional arguments:
  -h, --help            show this help message and exit
  -s SIGNAL, --signal SIGNAL
                        Input WAV signal
  -n NAME, --name NAME  Identifier for signal
  -o OUTPATH, --outpath OUTPATH
                        Output prefix for results

'''

# bandcloud-validator.com
# b@ndcl0ud!
ssh -i ~/.ssh/emrKey.pem ec2-user@XYZ
ssh -i ~/.ssh/emrKey.pem hadoop@YYZ



# Submit spark job
APP_REPO="986224559876.dkr.ecr.eu-west-1.amazonaws.com/audio-validation"
spark-submit --master yarn \
    --deploy-mode cluster \
    --conf spark.executorEnv.YARN_CONTAINER_RUNTIME_TYPE=docker \
    --conf spark.executorEnv.YARN_CONTAINER_RUNTIME_DOCKER_IMAGE="${APP_REPO}" \
    --conf spark.yarn.appMasterEnv.YARN_CONTAINER_RUNTIME_TYPE=docker \
    --conf spark.yarn.appMasterEnv.YARN_CONTAINER_RUNTIME_DOCKER_IMAGE="${APP_REPO}" \
    /usr/lib/python3.7/site-packages/audioValidator/run-comparator.py --help

'''

- Is it more that code can be referenced from container?

22/11/23 15:39:48 INFO Client: Uploading resource file:/usr/lib/python3.7/site-packages/audioValidator/run-comparator.py -> hdfs://ip-192-168-2-154.eu-west-1.compute.internal:8020/user/hadoop/.sparkStaging/application_1669217616031_0001/run-comparator.py
File file:/usr/lib/python3.7/site-packages/audioValidator/run-comparator.py does not exist
'''

#
# There are a lot useful details in log,
#  zeroing in permission issues from app logs
#
# Fails on master & core node
# DOCKER_CLIENT_CONFIG=hdfs:///user/hadoop/config.json <= is for auto auth not enabled
# application_1669288897165_0001
# 
vi audioValidator-Test.py
APP_REPO="986224559876.dkr.ecr.eu-west-1.amazonaws.com/audio-validation:latest"
spark-submit --master 'yarn' \
    --deploy-mode 'cluster' \
    --conf "spark.executorEnv.YARN_CONTAINER_RUNTIME_TYPE=docker" \
    --conf "spark.executorEnv.YARN_CONTAINER_RUNTIME_DOCKER_IMAGE=${APP_REPO}" \
    --conf "spark.yarn.appMasterEnv.YARN_CONTAINER_RUNTIME_TYPE=docker" \
    --conf "yarn.nodemanager.runtime.linux.docker.ecr-auto-authentication.enabled=true" \
    --conf "spark.yarn.appMasterEnv.YARN_CONTAINER_RUNTIME_DOCKER_IMAGE=${APP_REPO}" \
    audioVal-Test.py



'''
Shell error output: image: <ACCOUNT_ID>.dkr.ecr.eu-west-1.amazonaws.com/audio-validation is not trusted
no basic auth credentials.

For more detailed output, check the application tracking page: http://<DNS>:8088/cluster/app/application_1669217616031_0002 Then click on links to logs of each attempt.
. Failing the application.
Exception in thread "main" org.apache.spark.SparkException: Application application_1669217616031_0002 finished with failed status

'''


# Test that master can login
aws ecr get-login-password --region "eu-west-1" >> /dev/null
aws ecr get-login-password --region "eu-west-1" | docker login --username AWS --pass-stdin "${APP_REPO}"
docker run -it 986224559876.dkr.ecr.eu-west-1.amazonaws.com/audio-validation:latest

ssh -i ~/.ssh/emrKey.pem hadoop@192.168.2.159 "sudo usermod -a -G docker hadoop"


"""

- Given below edited allowed actions as per doc, resolved below error
https://docs.aws.amazon.com/AmazonECR/latest/userguide/security-iam-awsmanpol.html#security-iam-awsmanpol-AmazonEC2ContainerRegistryReadOnly
https://docs.aws.amazon.com/AmazonECR/latest/userguide/getting-started-cli.html#cli-authenticate-registry
https://docs.aws.amazon.com/AmazonECR/latest/userguide/registry_auth.html#registry_auth_http

- But not running the app even after logging in

An error occurred (AccessDeniedException) when calling the GetAuthorizationToken operation:
User: arn:aws:sts::986224559876:assumed-role/EMR_EC2_DefaultRole/<Instance ID>is not authorized to perform: ecr:GetAuthorizationToken on resource:
* because no identity-based policy allows the ecr:GetAuthorizationToken action


- Tried running on core/task node:
   => They were misconfigured.
   => Adding hadoop user to group allowed to run docker resolved.
   => Testing out on cluster w/out kerberos after encountering Kerberos error:
       => Cant get kerberos realm, cannot locate default realm
       => Made realm during cluster creation, dont think that docker container can ping it

docker: Got permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock: Post "http://%2Fvar%2Frun%2Fdocker.sock/v1.24/containers/create": dial unix /var/run/docker.sock: connect: permission denied.


- Worked fine, just bug in app code & worked fine after fixing

22/11/24 12:42:44 ERROR ApplicationMaster: User application exited with status 1
22/11/24 12:42:44 INFO ApplicationMaster: Final app status: FAILED, exitCode: 13, (reason: User application exited with status 1)
22/11/24 12:42:44 ERROR ApplicationMaster: Uncaught exception: 
org.apache.spark.SparkException: Exception thrown in awaitResult: 

['AudioValGenerator', '__builtins__', '__cached__', '__doc__', '__file__', '__loader__', '__name__', '__package__', '__spec__', 'json', 'librosa', 'np', 'plt', 'sf']

"""


# Scope out logs
clustDir="s3://bk-spark-cluster-tf/spark/j-10DR8KE2VRO5I/node"
clustMast="${clustDir}/i-0e77da9305f8f124f"
appLogs="s3://bk-spark-cluster-tf/spark/j-10DR8KE2VRO5I/containers/application_1669292513789_0001"

hdfs dfs -cat ${clustMast}/applications/spark/spark-history-server.out.gz | gzip -d - | less
hdfs dfs -cat ${clustMast}/applications/hadoop-yarn/hadoop-yarn-resourcemanager-ip-192-168-2-185.out.gz | gzip -d - | less
hdfs dfs -cat ${clustMast}/daemons/instance-state/instance-state.log-2022-11-24-12-30.gz | gzip -d - | less
hdfs dfs -cat ${appLogs}/container_1669292513789_0001_01_000001/stdout.gz | gzip -d - | less
yarn logs -applicationId application_1669292513789_0002 | less



###################################################
# 
# Kerberos Docker
# 
# - Add kerberos config as read only mount
#     => Yarn & Spark Executors
#
# References:
#  https://docs.cloudera.com/cdp-private-cloud-base/latest/yarn-troubleshooting/topics/yarn-troubleshooting-docker.html?
# 
###################################################


# Run app without mount
APP_REPO="986224559876.dkr.ecr.eu-west-1.amazonaws.com/audio-validation:latest"
spark-submit \
    --master 'yarn' \
    --deploy-mode 'cluster' \
    --conf "spark.executorEnv.YARN_CONTAINER_RUNTIME_TYPE=docker" \
    --conf "spark.executorEnv.YARN_CONTAINER_RUNTIME_DOCKER_IMAGE=${APP_REPO}" \
    --conf "spark.yarn.appMasterEnv.YARN_CONTAINER_RUNTIME_TYPE=docker" \
    --conf "yarn.nodemanager.runtime.linux.docker.ecr-auto-authentication.enabled=true" \
    --conf "spark.yarn.appMasterEnv.YARN_CONTAINER_RUNTIME_DOCKER_IMAGE=${APP_REPO}" \
    audioVal-Test.py

"""

22/11/24 15:14:06 INFO SecurityManager: Changing view acls to: hadoop
22/11/24 15:14:06 INFO SecurityManager: Changing modify acls to: hadoop
22/11/24 15:14:06 INFO SecurityManager: Changing view acls groups to: 
22/11/24 15:14:06 INFO SecurityManager: Changing modify acls groups to: 
22/11/24 15:14:06 INFO SecurityManager: SecurityManager: authentication disabled; ui acls disabled; users  with view permissions: Set(hadoop); groups with view permissions: Set(); users  with modify permissions: Set(hadoop); groups with modify permissions: Set()
22/11/24 15:14:06 INFO HadoopDelegationTokenManager: Attempting to load user's ticket cache.
22/11/24 15:14:06 INFO HadoopFSDelegationTokenProvider: getting token for: DFS[DFSClient[clientName=DFSClient_NONMAPREDUCE_-1221950100_1, ugi=hadoop/ip-192-168-2-135.eu-west-1.compute.internal@bandcloud-validator.com (auth:KERBEROS)]] with renewer yarn/ip-192-168-2-135.eu-west-1.compute.internal@bandcloud-validator.com
22/11/24 15:14:06 INFO DFSClient: Created token for hadoop: HDFS_DELEGATION_TOKEN owner=hadoop/ip-192-168-2-135.eu-west-1.compute.internal@bandcloud-validator.com, renewer=yarn, realUser=, issueDate=1669302846456, maxDate=1669907646456, sequenceNumber=1, masterKeyId=2 on 192.168.2.135:8020
22/11/24 15:14:06 INFO KMSClientProvider: New token created: (Kind: kms-dt, Service: kms://http@ip-192-168-2-135.eu-west-1.compute.internal:9600/kms, Ident: (kms-dt owner=hadoop, renewer=yarn, realUser=, issueDate=1669302846711, maxDate=1669907646711, sequenceNumber=1, masterKeyId=2))
22/11/24 15:14:06 INFO HadoopFSDelegationTokenProvider: getting token for: DFS[DFSClient[clientName=DFSClient_NONMAPREDUCE_-1221950100_1, ugi=hadoop/ip-192-168-2-135.eu-west-1.compute.internal@bandcloud-validator.com (auth:KERBEROS)]] with renewer hadoop/ip-192-168-2-135.eu-west-1.compute.internal@bandcloud-validator.com
22/11/24 15:14:06 INFO DFSClient: Created token for hadoop: HDFS_DELEGATION_TOKEN owner=hadoop/ip-192-168-2-135.eu-west-1.compute.internal@bandcloud-validator.com, renewer=hadoop, realUser=, issueDate=1669302846958, maxDate=1669907646958, sequenceNumber=2, masterKeyId=2 on 192.168.2.135:8020
22/11/24 15:14:06 INFO KMSClientProvider: New token created: (Kind: kms-dt, Service: kms://http@ip-192-168-2-135.eu-west-1.compute.internal:9600/kms, Ident: (kms-dt owner=hadoop, renewer=hadoop, realUser=, issueDate=1669302846991, maxDate=1669907646991, sequenceNumber=2, masterKeyId=2))

22/11/24 15:37:19 INFO Client: Application report for application_1669302722732_0002 (state: ACCEPTED)
22/11/24 15:37:59 INFO Client: Application report for application_1669302722732_0002 (state: FAILED)


22/11/24 15:37:58 INFO SignalUtils: Registering signal handler for TERM
22/11/24 15:37:58 INFO SignalUtils: Registering signal handler for HUP
22/11/24 15:37:58 INFO SignalUtils: Registering signal handler for INT
22/11/24 15:37:58 INFO SecurityManager: Changing view acls to: hadoop
22/11/24 15:37:58 INFO SecurityManager: Changing modify acls to: hadoop
22/11/24 15:37:58 INFO SecurityManager: Changing view acls groups to: 
22/11/24 15:37:58 INFO SecurityManager: Changing modify acls groups to: 
22/11/24 15:37:58 INFO SecurityManager: SecurityManager: authentication disabled; ui acls disabled; users  with view permissions: Set(hadoop); groups with view permissions: Set(); users  with modify permissions: Set(hadoop); groups with modify permissions: Set()
Exception in thread 'main' java.lang.IllegalArgumentException: Can't get Kerberos realm
Caused by: KrbException: Cannot locate default realm

"""


#
# Run app with read only mount
# src:dest:mode
#  => ro, rw
#
APP_REPO="986224559876.dkr.ecr.eu-west-1.amazonaws.com/audio-validation:latest"
spark-submit --master 'yarn' \
    --deploy-mode 'cluster' \
    --conf "spark.executorEnv.YARN_CONTAINER_RUNTIME_TYPE=docker" \
    --conf "spark.executorEnv.YARN_CONTAINER_RUNTIME_DOCKER_IMAGE=${APP_REPO}" \
    --conf "spark.yarn.appMasterEnv.YARN_CONTAINER_RUNTIME_TYPE=docker" \
    --conf "yarn.nodemanager.runtime.linux.docker.ecr-auto-authentication.enabled=true" \
    --conf "spark.yarn.appMasterEnv.YARN_CONTAINER_RUNTIME_DOCKER_IMAGE=${APP_REPO}" \
    --conf "spark.yarn.appMasterEnv.YARN_CONTAINER_RUNTIME_DOCKER_MOUNTS=/etc/krb5.conf:/etc/krb5.conf:ro" \
    --conf "spark.executorEnv.YARN_CONTAINER_RUNTIME_DOCKER_MOUNTS=/etc/krb5.conf:/etc/krb5.conf:ro" \
    audioVal-Test.py


"""

diagnostics: Application application_1669302722732_0001 failed 2 times due to AM Container for appattempt_1669302722732_0001_000002 exited with  exitCode: 29
Failing this attempt.Diagnostics: [2022-11-24 15:14:22.696]Exception from container-launch.
Exit code: 29
Exception message: Launch container failed
Shell error output: Configuration does not allow docker mount '/etc/krb5.conf:/etc/krb5.conf:ro', realpath=/etc/krb5.conf
Error constructing docker command, docker error code=14, error message='Invalid docker read-only mount'


- Need to set what docker is allowed to mount

"""


# Check allowed mount
for i in $(ls /etc/hadoop/conf/*); do grep -li "docker" ${i}; done
cat -n /etc/hadoop/conf/yarn-site.xml | grep "docker" | less


'''

- Candidates to search

/etc/hadoop/conf/container-executor.cfg
/etc/hadoop/conf/yarn-site.xml


- Can the container executor be edited like in the docker-conf?


"docker.trusted.registries": "local,centos,986224559876.dkr.ecr.eu-west-1.amazonaws.com",
"docker.privileged-containers.registries": "local,centos,986224559876.dkr.ecr.eu-west-1.amazonaws.com"
"docker.allowed.ro-mounts: "/sys/fs/cgroup,/etc/passwd,/usr/lib,/usr/share,/etc/krb5.conf"

/etc/hadoop/conf/container-executor.cfg

docker.allowed.ro-mounts=/sys/fs/cgroup,/etc/passwd,/usr/lib,/usr/share


- Yarn conf has similar data, should be mindful how this changes once edited

   196      <name>yarn.nodemanager.runtime.linux.docker.default-ro-mounts</name>
   197      <value>/etc/passwd:/etc/passwd,/usr/lib:/docker/usr/lib,/usr/share:/docker/usr/share</value>

'''

# Check configuration updates
less /etc/hadoop/conf/container-executor.cfg 


'''

- Container config changed

[docker]
docker.allowed.ro-mounts=/sys/fs/cgroup,/etc/passwd,/usr/lib,/usr/share,/etc/krb5.conf


- No changes in Yarn-Site config

  <property>
    <name>yarn.nodemanager.runtime.linux.docker.default-ro-mounts</name>
    <value>/etc/passwd:/etc/passwd,/usr/lib:/docker/usr/lib,/usr/share:/docker/usr/share</value>
  </property>

'''

# Test after updating cluster-wide config
APP_REPO="986224559876.dkr.ecr.eu-west-1.amazonaws.com/audio-validation:latest"
spark-submit --master 'yarn' \
    --deploy-mode 'cluster' \
    --conf "spark.executorEnv.YARN_CONTAINER_RUNTIME_TYPE=docker" \
    --conf "spark.executorEnv.YARN_CONTAINER_RUNTIME_DOCKER_IMAGE=${APP_REPO}" \
    --conf "spark.yarn.appMasterEnv.YARN_CONTAINER_RUNTIME_TYPE=docker" \
    --conf "yarn.nodemanager.runtime.linux.docker.ecr-auto-authentication.enabled=true" \
    --conf "spark.yarn.appMasterEnv.YARN_CONTAINER_RUNTIME_DOCKER_IMAGE=${APP_REPO}" \
    --conf "spark.yarn.appMasterEnv.YARN_CONTAINER_RUNTIME_DOCKER_MOUNTS=/etc/krb5.conf:/etc/krb5.conf:ro" \
    --conf "spark.executorEnv.YARN_CONTAINER_RUNTIME_DOCKER_MOUNTS=/etc/krb5.conf:/etc/krb5.conf:ro" \
    audioVal-Test.py


"""

- BOOM!!!!!


22/11/24 16:44:11 INFO Client: Application report for application_1669308015204_0002 (state: RUNNING)
22/11/24 16:44:11 INFO Client: 
         client token: Token { kind: YARN_CLIENT_TOKEN, service:  }
         diagnostics: N/A

22/11/24 16:44:12 INFO Client: Application report for application_1669308015204_0002 (state: RUNNING)
22/11/24 16:44:13 INFO Client: Application report for application_1669308015204_0002 (state: FINISHED)


"""


#######################################
#######################################
# 
# EMR-EKS
#  => What is the benefit?
#
# References:
# https://docs.aws.amazon.com/emr/latest/EMR-on-EKS-DevelopmentGuide/virtual-cluster.html
# 
#######################################
#######################################







