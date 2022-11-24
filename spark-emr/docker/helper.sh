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

ssh -i ~/.ssh/emrKey.pem hadoop@192.168.2.169 "sudo usermod -a -G docker hadoop"


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