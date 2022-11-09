##########################################################
##########################################################
# 
# 
# 
##########################################################
##########################################################

#######################################
#######################################
#
# 1). AMI for managing cluster
#
#######################################
#######################################


# Install terraform etc
sudo su
yum update -y
yum install -y yum-utils git
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
yum -y install terraform


# Fetch repo
git clone --recursive https://github.com/BrenKenna/audioValidation.git
aws iam delete-instance-profile --region "eu-west-1" --instance-profile-name "spark-emr-profile"


# Create image with Tf, git & repo
aws ec2 create-image \
    --instance-id "i-0306e4352de2a05f0" \
    --name "emrTerraformAMI" \
    --description "Managing an audio validation cluster"


# Setup
terraform init


# Plan resources
terraform plan


# Create resources
terraform apply


#####################################################
#####################################################
# 
# 2). Install audio software
# => What changes needed for EMR?
#     a). Remotely issue background pip +
#          fetch tar?
#     b). What boostrap is for?
#     c). ECR container for app, run container?
#
#####################################################
#####################################################

# Install via pip
pip install librosa matplotlib numpy pandas scikit-learn

# Via conda dependencies: numba could throw weird error, think this >0.53 or something
conda install -y matplotlib scikit-learn pandas numpy
conda install -y librosa

# Add to path
export PATH="${PATH}:/c/Users/kenna/anaconda3/pkgs:/c/Users/kenna/OneDrive/Documents/GitHub/audioValidation/audioValidator"


# Test run with example output
python run-generator.py -m "generator/goat-java.txt" -n "Goat Java"

'''

Proceeding with generator/goat-java.txt

Signal generated for:   Goat Java
Generated wave: 70014
Sampling Rate:  2000

'''

# Generate results
python run-results-maker.py -s "examples\test\Tempest-Temper-Enlil-Enraged.wav" -n "Melechesh"

# Generate classification
python run-comparator.py -s "examples\test\Tempest-Temper-Enlil-Enraged.wav" -n "Melechesh"


###############################
###############################
# 
# Fun time with scripts
# 
###############################
###############################


# Run example script
bash mockSignal-runner.sh


# Setup
mkdir tempDir resultsDir
for inp in $( cat text-examples.txt )
    do

    # Fetch
    base=$(basename ${inp} | cut -d \. -f 1)
    curl -o tempDir/${base}.txt ${inp}

    # Generate mock audio signal
    python run-generator.py -m "tempDir/${base}.txt" -n "${base}"

    # Analyze
    python run-comparator.py -s "${base}.wav" -n "${base}"
done


###########################################
###########################################
# 
# 3). Private EMR Cluster
#  => Move onto debugging running app
#  => Public cluster
#  => Console logs post cluster spin-up
#  => S3 logs post sping-up
#  => Logs post:
#      a). CPU Load
#      b). Storage-FS
#      c). Storage-HDFS
#      d). Stopping nodes
#  => Different instance types
#  => Additions to SGs
# 
###########################################
###########################################



######################################
# 
# a). Debug Internet Access
#  => Cluster spin-up >1hr
#  => Should be 15-25 mins
#  => Emphemeral In & Out anywhere
# 
######################################

# Swap main.tf
cd spark-emr/terraform
mv main.tf old-main.txt
mv main-internet-debug.tf main.tf
mv outputs.tf old-outputs.txt


# Copy key for testing
scp -pi ~/.ssh/emrKey.pem ~/.ssh/emrKey.pem ec2-user@54.246.5.203:~/.ssh/
ssh -i ~/.ssh/emrKey.pem ec2-user@54.246.5.203


# 
# From bastion
# As suspected broadening NACL rules resolved
ssh -i ~/.ssh/emrKey.pem hadoop@192.168.2.96
curl https://amazon.com
ping -c 4 -4 google.com


"""

- Cluster progressed to TaskGroups following debugging internet access
  by replacing cluster + bastion host with respective ec2 instance

aws_emr_cluster.spark-cluster: Still creating... [13m0s elapsed]
aws_emr_cluster.spark-cluster: Still creating... [13m10s elapsed]
aws_emr_cluster.spark-cluster: Creation complete after 13m14s [id=j-2D8FWHRVV91T1]
aws_emr_instance_group.task_group: Creating...
aws_emr_instance_group.task_group: Still creating... [10s elapsed]
aws_emr_instance_group.task_group: Still creating... [20s elapsed]
aws_emr_instance_group.task_group: Still creating... [30s elapsed]


- Task nodes did enter a 'resizing' state, instance type used?
   => Did complete though

aws_emr_instance_group.task_group: Still creating... [6m10s elapsed]
aws_emr_instance_group.task_group: Still creating... [6m20s elapsed]

aws_emr_instance_group.task_group: Creation complete after 9m42s [id=ig-1M2U7KLUGUU9O]

Apply complete! Resources: 44 added, 0 changed, 0 destroyed.

Outputs:

cluster-id = 'j-2D8FWHRVV91T1'
cluster-loggingBucket = 's3://spark-cluster-tf/spark/'
cluster-name = 'EMR Terraform Cluster'
head-node = 'ip-192-168-2-96.eu-west-1.compute.internal'


- Spin down +10mins, comeback to SG additions for config & then handling spin down

Wed 26 Oct 20:53:45 UTC 2022

"""

# Note on removing IGW while Nat is attached

"""

- IGW cannot be dependent on NAT

Error: error waiting for EC2 NAT Gateway (nat-0e21891f82005a9b7) create: unexpected state 'failed', wanted target 'available'. last error: Gateway.NotAttached: Network vpc-0f5754232efa349a2 has no Internet gateway attached

"""

# Run again
git clone --recursive https://github.com/BrenKenna/audioValidation.git
cd ~/audioValidation/spark-emr/terraform
mv main-internet-debug.tf old-main-internet-debug.txt
terraform init
terraform plan

'''

- Testing again the following day works fine, ~30mins

aws_nat_gateway.nat-cluster: Creation complete after 2m14s [id=nat-00eec0dbb4cd006d4]
aws_route_table.cluster-rtb-priv: Creating...
aws_route_table.cluster-rtb-priv: Creation complete after 0s [id=rtb-01e70f02bdc0d7411]
aws_route.cluster-nat-route: Creating...
aws_route.cluster-nat-route: Creation complete after 1s [id=r-rtb-01e70f02bdc0d74111080289494]
aws_route_table_association.cluster-rta: Creating...
...
aws_route_table_association.cluster-rta: Still creating... [2m40s elapsed]
aws_route_table_association.cluster-rta: Creation complete after 2m44s [id=rtbassoc-063bf54e1716075b1]
aws_emr_cluster.spark-cluster: Creating...
...
aws_emr_cluster.spark-cluster: Creation complete after 14m5s [id=j-34UG8041EV0W6]
...
aws_emr_instance_group.task_group: Still creating... [9m20s elapsed]
aws_emr_instance_group.task_group: Creation complete after 9m21s [id=ig-FYDYJTF645FR]

Apply complete! Resources: 44 added, 0 changed, 0 destroyed.

Outputs:

cluster-id = "j-34UG8041EV0W6"
cluster-loggingBucket = "s3://spark-cluster-tf/spark/"
cluster-name = "EMR Terraform Cluster"
head-node = "ip-192-168-2-231.eu-west-1.compute.internal"

'''

########################################################
########################################################
# 
# b). Custom App
# 
# - Current aim bootstrap script:
#    => Setup a script from spun-up cluster
#    => Copy spin-up client command
#    => Debug
#    => Bang into the terraform code
# 
# 
# - Long-term view:
#    => Boostrap shell script with docker
#    => Fetch & run container
#
# References:
# 1). Custom Software: https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-plan-software.html
# 2). Boostrap Script: https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-plan-bootstrap.html
# 3). Spark Containers: https://docs.aws.amazon.com/emr/latest/ReleaseGuide/emr-spark-docker.html
# 
########################################################
########################################################



################################
################################
# 
# 1). Boostrap script
#
#   a). Via pip
#   b). Via Miniconda
# 
################################
################################


#######################
#######################
# 
# a). Pip
# 
#######################
#######################


# Login to bastion
scp -pi ~/.ssh/emrKey.pem ~/.ssh/emrKey.pem ec2-user@52.50.126.212:~/.ssh/
ssh -i ~/.ssh/emrKey.pem ec2-user@52.50.126.212


# Login to master
scp -pi ~/.ssh/emrKey.pem ~/.ssh/emrKey.pem hadoop@192.168.2.146:~/.ssh/
ssh -i ~/.ssh/emrKey.pem hadoop@192.168.2.146


# Install core packages
sudo yum install -y libsndfile.x86_64 libsndfile-utils.x86_64 libsndfile-devel.x86_64
sudo pip3 install pysoundfile
sudo pip3 install librosa matplotlib numpy pandas scikit-learn
sudo pip3 install boto3

python -c 'import librosa'


"""

- First attempt without pysoundfile and libsnd

Installing collected packages: charset-normalizer, idna, certifi, urllib3, requests, appdirs, pyparsing,
packaging, pooch, pycparser, cffi, soundfile, audioread, zipp, typing-extensions, importlib-metadata,
llvmlite, numba, resampy, scipy, threadpoolctl, scikit-learn, decorator, librosa,
kiwisolver, fonttools, python-dateutil, cycler, pillow, matplotlib, pandas
WARNING: The script normalizer is installed in '/home/hadoop/.local/bin' which is not on PATH.


Running setup.py install for audioread ... done
  WARNING: The scripts fonttools, pyftmerge, pyftsubset and ttx are installed in '/home/hadoop/.local/bin' 
  which is not on PATH.
  Consider adding this directory to PATH or, if you prefer to suppress this warning, use --no-warn-script-location.

"""


# Install the audioValidator
sudo yum install -y git
git clone --recursive https://github.com/BrenKenna/audioValidation.git
cd audioValidation
rm -fr Figs/ spark-emr/ helper.sh README.md links.txt
sudo mv audioValidator/ /usr/lib/python3.7/site-packages/

#
# Holding on to see installation ocurred
# cd ~
# rm -fr audioValidation/
# 

# Test imports: Can instantiate compartor
# sudo su; cd /usr/lib/python3.7/site-packages/audioValidator/comparator
python -c '
from audioValidator.comparator import comparator as avc
audioVal = avc.AudioValComparator()
audioVal.loadTrainingSet()
print(audioVal.data)
'


'''

                      Track                            Track Name  Mean Played/s  Mean Not Played/s  ...  File Size MB    MB / s  Label  Notes / Tempo
0                      Goat               generator/goat-java.wav       3.200000           8.800000  ...      0.133583  0.003817      1       0.000000
1                Collection         generator/collection-java.wav       3.391304           8.608696  ...      0.262825  0.003865      1       0.000000
2           Half-Compendium         generator/half-compendium.wav       1.020000          10.980000  ...     33.638714  0.336387      1       0.000000
3                Compendium              generator/compendium.wav       1.320000          10.680000  ...     67.277388  0.672774      1       0.000000
4               Wihing Well             examples/Wishing-Well.wav       1.100000          10.900000  ...      7.572258  0.063102      0       0.919510
5                     Stomp                    examples/Stomp.wav       1.041667          10.958333  ...      7.437532  0.061979      0       1.064248
6              Beat Goes on     examples/And-the-Beat-Goes-On.wav       0.925000          11.075000  ...     12.373756  0.103115      0       0.988009
7                  Sir Duke                 examples/Sir-Duke.wav       0.875000          11.125000  ...      7.264542  0.060538      0       0.975238
8               Wihing Well             examples/Wishing-Well.wav       1.100000          10.900000  ...      7.572258  0.063102      0       0.919510
9         Give Me the Night        examples/Give-Me-The-Night.wav       0.941667          11.058333  ...      6.829273  0.056911      0       1.005811
10  Thorns of Crimson Death  examples/Thorns-of-Crimson-Death.wav       1.183333          10.816667  ...     14.892889  0.124107      0       0.989170

[11 rows x 15 columns]

'''


# Copy and add in boostrap script
bash spinup-cluster.sh

'''

{
    "ClusterId": "j-3T6QL946RHU2E", 
    "ClusterArn": "arn:aws:elasticmapreduce:eu-west-1:986224559876:cluster/j-3T6QL946RHU2E"
}

'''

# Spunup fine and audioValidator works
python -c '
from audioValidator.comparator import comparator as avc
audioVal = avc.AudioValComparator()
audioVal.loadTrainingSet()
print(audioVal.data)
'


# Works from pyspark too
pyspark
from audioValidator.comparator import comparator as avc
audioVal = avc.AudioValComparator()
audioVal.loadTrainingSet()

'''


[11 rows x 15 columns]
>>> 
'''

# Kill cluster
aws emr terminate-clusters \
  --region "eu-west-1" \
  --cluster-ids "j-3T6QL946RHU2E"


#######################
#######################
# 
# b). Miniconda
# 
#######################
#######################

# Python 3.7.10
# Via conda dependencies: numba could throw weird error, think this >0.53 or something
export SOFTWARE=~/software
export CMAKE_PREFIX_PATH="~/software"
export PATH=${SOFTWARE}/bin:$PATH
wget -q https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
chmod +x Miniconda3-latest-Linux-x86_64.sh
./Miniconda3-latest-Linux-x86_64.sh -u -b -p ${SOFTWARE}


# Install packages
conda install -y python=3.7.10
conda install -y matplotlib scikit-learn pandas numpy
conda install -yc conda-forge pysoundfile librosa


'''
- Worked fine, try adding to path

software/bin/python3.7
Python 3.7.10 (default, Jun  4 2021, 14:48:32) 
[GCC 7.5.0] :: Anaconda, Inc. on linux
Type "help", "copyright", "credits" or "license" for more information.
>>> import soundfile
>>> import librosa

'''

# Load librosa from pySpark
export PYTHONPATH="${SOFTWARE}/lib/python3.7/site-packages:/usr/lib/python3.7/site-packages"
python -c 'import soundfile, librosa'
# pyspark


sudo su
echo -e "
export SOFTWARE=~/software
export CMAKE_PREFIX_PATH=\"~/software\"
export PATH=${SOFTWARE}/bin:$PATH
export PYTHONPATH=\"${SOFTWARE}/lib/python3.7/site-packages:/usr/lib/python3.7/site-packages\"
" > /etc/profile.d/audioVal-vars.sh
exit
echo "source /etc/profile.d/audioVal-vars.sh" >> ~/.bashrc


"""

- Worked fine, comeback to root installation via pip

SparkSession available as 'spark'.
>>> 
>>> 
>>> import soundfile
>>> import librosa
>>> 


- Temp workaround

while [ ! -f ~/.bashrc ]
  do
  sleep 5s
done

OR

while [ `wc -l /etc/profile | awk '{ print $1 }'` -lt 76 ]
  do
  sleep 5s
done

wc -l /etc/profile
76 /etc/profile
"""



################################
################################
# 
# 2). Run app
#
#   a). Download
#   b). Analyze
#   c). Post
# 
# - Clusters to check
#   j-1JHJFK4C24QPM, j-DHIV6JGGHIKY
#   j-SUPT2CI91N4D, j-2ATIIN9RSTV47
#   j-14591FGIPAMC5, j-1XHWODSTSREGC
#
################################
################################


# Check status
aws emr describe-cluster \
  --region "eu-west-1" \
  --cluster "j-DHIV6JGGHIKY" \
  --query "Cluster.Status"

'''

{
    "Timeline": {
        "ReadyDateTime": 1666953568.902, 
        "CreationDateTime": 1666952656.129
    }, 
    "State": "WAITING", 
    "StateChangeReason": {
        "Message": "Cluster ready to run steps."
    }
}

'''


# Install jq
sudo yum install -y jq

# List data fine
aws s3 ls s3://band-cloud-audio-validation/real/

'''

2022-10-28 08:42:16   12974824 And-the-Beat-Goes-On.wav
2022-10-28 08:42:16    6986226 Feel-So-Numb.wav
2022-10-28 08:42:16    7161012 Give-Me-The-Night.wav
2022-10-28 08:42:16    7714290 God-of-Thunder.wav

'''


# Test script
mkdir examples/
aws s3 cp s3://band-cloud-audio-validation/real/Tempest-Temper-Enlil-Enraged.wav examples/
python /usr/lib/python3.7/site-packages/audioValidator/run-results-maker.py \
  -s "examples/Tempest-Temper-Enlil-Enraged.wav" \
  -n "Melechesh"
cat Melechesh-results.json | jq '.'

'''

- Analyzer runs fine

Proceeding with examples/Tempest-Temper-Enlil-Enraged.wav


Reading audio signal & measuring tempo

Separating haromic from percussive signal for chromagram analysis


{
  "Track": "Melechesh",
  "Track Name": "examples/Tempest-Temper-Enlil-Enraged.wav",
  "Mean Played/s": 1.7083333333333333,
  "Mean Not Played/s": 10.291666666666666,
  "Played Sum": 205,
  "Not Played Sum": 1235,
  "Played Size": 120,
  "Length seconds": 120,
  "Tempo": 123.046875,
  "Wave Size": 2646000,
  "Sampling Rate": 22050,
  "File Size MB": 11.96605110168457,
  "MB / s": 0.09971709251403808,
  "Notes / Tempo": 1.666031746031746
}

'''


# Test classifier
python /usr/lib/python3.7/site-packages/audioValidator/run-comparator.py \
  -s "examples/Tempest-Temper-Enlil-Enraged.wav" \
  -n "Melechesh"
 sed -e 's/^"//g' -e 's/"$//g' -e 's/\\//g' Melechesh-classification.json | jq '."0"'

'''

- Runs fine


Proceeding with examples/Tempest-Temper-Enlil-Enraged.wav


Reading audio signal & measuring tempo

Separating haromic from percussive signal for chromagram analysis

Analyzing results and summarizing for classifier


Fetching training model

Applying classifier


Handling results

Melechesh label = 0


{
  "Track": "Melechesh",
  "Track Name": "examples/Tempest-Temper-Enlil-Enraged.wav",
  "Mean Played/s": 1.7083333333,
  "Mean Not Played/s": 10.2916666667,
  "Played Sum": 205,
  "Not Played Sum": 1235,
  "Played Size": 120,
  "Length seconds": 120,
  "Tempo": 123.046875,
  "Wave Size": 2646000,
  "Sampling Rate": 22050,
  "File Size MB": 11.9660511017,
  "MB / s": 0.0997170925,
  "Notes / Tempo": 1.666031746,
  "Label": 0
}

'''


#####################
# 
# b). Fetch Tracks
# 
#####################


# Downlaod
for track in $(aws s3 ls s3://band-cloud-audio-validation/real/ | awk '{ print $NF }' | sort -R | head -n 4)
  do
  aws s3 cp s3://band-cloud-audio-validation/real/${track} examples/
done


#################

# Debug analyzing
pyspark --master 'local[1]'
spark = SparkSession.builder.getOrCreate()
sc = spark.context

"""

Using Python version 3.7.10 (default, Jun  3 2021 00:02:01)
Spark context Web UI available at http://ip-192-168-2-119.eu-west-1.compute.internal:4040
Spark context available as 'sc' (master = local[1], app id = local-1666953708214).
SparkSession available as 'spark'.

"""

# Import modules
import os, sys, boto3
import json
import matplotlib.pyplot as plt
import pandas as pd


# Audio validator
from audioValidator.generator import generator
from audioValidator.results import results
from audioValidator.comparator import comparator
from audioValidator.utils import utils


# s3 config
bucket = "band-cloud-audio-validation"
s3_client = boto3.client('s3')


# Configure analysis list
dataDir = '/home/hadoop/examples/'
toDo = []
for track in os.listdir(dataDir):
  trackName = track.replace('.wav', '')
  toDo.append( (trackName, str(dataDir + track)) )


# Options: foreach, map
# outMap = list(map( utils.classifyAudioSignal_fromTuple, toDo ))
toDo_spark = sc.parallelize(toDo)
output = toDo_spark.map(utils.classifyAudioSignal_fromTuple).collect()


# Print results
print(json.dumps(
    output,
    indent = 2
))

'''

[
  {
    "Track": "God-of-Thunder",
    "Track Name": "/home/hadoop/examples/God-of-Thunder.wav",
    "Mean Played/s": 1.1416666667,
    "Mean Not Played/s": 10.8583333333,
    "Played Sum": 137,
    "Not Played Sum": 1303,
    "Played Size": 120,
    "Length seconds": 120,
    "Tempo": 107.666015625,
    "Wave Size": 2646000,
    "Sampling Rate": 22050,
    "File Size MB": 7.3569202423,
    "MB / s": 0.0613076687,
    "Notes / Tempo": 1.2724535147,
    "Label": 0
  },
  {
    "Track": "Feel-So-Numb",
  ...
  },
  ...
]

'''


# Run again: First was 0001
pyspark --master 'yarn'

"""


Using Python version 3.7.10 (default, Jun  3 2021 00:02:01)
Spark context Web UI available at http://ip-192-168-2-119.eu-west-1.compute.internal:4040
Spark context available as 'sc' (master = yarn, app id = application_1666953345948_0002).
SparkSession available as 'spark'.

"""

# Import modules
import os, sys, boto3
import json
import matplotlib.pyplot as plt
import pandas as pd


# Audio validator
from audioValidator.generator import generator
from audioValidator.results import results
from audioValidator.comparator import comparator
from audioValidator.utils import utils


# s3 config
bucket = "band-cloud-audio-validation"
s3_client = boto3.client('s3')


# Configure analysis list
dataDir = '/home/hadoop/examples/'
toDo = []
for track in os.listdir(dataDir):
  trackName = track.replace('.wav', '')
  toDo.append( (trackName, str(dataDir + track)) )


# Options: foreach, map
# outMap = list(map( utils.classifyAudioSignal_fromTuple, toDo ))
toDo_spark = sc.parallelize(toDo)
output = toDo_spark.map(utils.classifyAudioSignal_fromTuple).collect()

"""

RuntimeError: cannot cache function '__shear_dense': no locator available for file '/usr/local/lib/python3.7/site-packages/librosa/util/utils.py'


"""


#########################
#########################


# Run local pyspark session
pyspark --master 'yarn'


# Import modules
import os, sys, boto3, shutil
import json
import matplotlib.pyplot as plt
import pandas as pd


# Set numba cache dir before librosa import
os.environ["NUMBA_CACHE_DIR"] = "/tmp/NUMBA_CACHE_DIR/"
from audioValidator.generator import generator
from audioValidator.results import results
from audioValidator.comparator import comparator
from audioValidator.utils import utils


# s3 config
import boto3
bucket = "band-cloud-audio-validation"
prefix = "real/"
s3_client = boto3.client('s3')
response = s3_client.list_objects(Bucket = bucket, Prefix = prefix)


# Setup work
toDo = []
for obj in response["Contents"]:
  outPath = str('./' + os.path.dirname(obj['Key']) + "/" + os.path.basename(obj['Key']).replace('.wav', '') )
  item = (bucket, obj['Key'], outPath)
  toDo.append(item)


# Run analysis
# outMap = list(map( utils.runFetchAndClassify, toDo ))
toDo_spark = sc.parallelize(toDo)
output = toDo_spark.map(utils.runFetchAndClassify).collect()
[ print(i["Track"] + " = " + str(i["Label"])) for i in output ]

"""


And-the-Beat-Goes-On = 0
Feel-So-Numb = 0
Give-Me-The-Night = 0
God-of-Thunder = 0
Grand-Gathas-of-Baal-Sin = 0
Sir-Duke = 0
Stomp = 0
Superbeast = 0
Tempest-Temper-Enlil-Enraged = 0
Thorns-of-Crimson-Death = 0
Wishing-Well = 0

"""

# Test submit
zip -r audioValidator.zip /usr/lib/python3.7/site-packages/audioValidator
spark-submit \
   --master yarn \
   --deploy-mode cluster \
   --py-files audioValidator.zip \
   audioValidator-test-job.py

yarn logs -applicationId application_1667324961020_0008 | less


"""

- Worked ok-ish, ~3mins for all instead of ~30mins
  => Some small things to comeback too like need for NUMBA cache dir with miniconda & friends
  => Managing print statements etc
  => yarn logs is deady handy in private subnet XD

22/11/01 19:14:19 INFO ClientConfigurationFactory: Set initial getObject socket timeout to 2000 ms.

22/11/01 19:17:23 INFO PythonRunner: Times: total = 183266, boot = 843, init = 6735, finish = 175688
22/11/01 19:17:23 INFO Executor: Finished task 0.0 in stage 0.0 (TID 0). 3163 bytes result sent to driver


- Seen in all containers, but doesn't crash tasks
  => Not really used, comeback laterzzz

Container: container_1667324961020_0008_01_000008 on ip-192-168-2-25.eu-west-1.compute.internal_8041
LogAggregationType: AGGREGATED

22/11/01 19:14:23 WARN ConfigurationUtils: Cannot create temp dir with proper permission: /mnt1/s3
java.nio.file.AccessDeniedException: /mnt1

And-the-Beat-Goes-On. = 0
Feel-So-Numb. = 0
Give-Me-The-Night. = 0
God-of-Thunder. = 0
Grand-Gathas-of-Baal-Sin. = 0
Sir-Duke. = 0
Stomp. = 0
Superbeast. = 0
Tempest-Temper-Enlil-Enraged. = 0
Thorns-of-Crimson-Death. = 0
Wishing-Well. = 0

- Jobs still ran, print statements are mess (lazy coding)
 => While there are errors for 

./real/Sir-Duke/Sir-Duke.wav
./real/And-the-Beat-Goes-On/And-the-Beat-Goes-On.wav
./real/Stomp/Stomp.wav
./real/Feel-So-Numb/Feel-So-Numb.wav
./real/Give-Me-The-Night/Give-Me-The-Night.wav
./real/Superbeast/Superbeast.wav
./real/God-of-Thunder/God-of-Thunder.wav
./real/Tempest-Temper-Enlil-Enraged/Tempest-Temper-Enlil-Enraged.wav
./real/Grand-Gathas-of-Baal-Sin/Grand-Gathas-of-Baal-Sin.wav
./real/Thorns-of-Crimson-Death/Thorns-of-Crimson-Death.wav


Error deleting track data: ./real/Thorns-of-Crimson-Death/Thorns-of-Crimson-Death.wav
Error deleting tree: ./real/Thorns-of-Crimson-Death

"""


# Run N jobs
date
for i in $(seq 15)
  do
  nohup spark-submit --master yarn --deploy-mode cluster --py-files audioValidator.zip audioValidator-test-job.py &>> audio-job-${i}.txt &
  sleep 3s
  wc -l audio-job-${i}.txt
done

tail -n 3 audio-job*txt

'''

- 15 test = still crashes
 => Tue  1 Nov 20:31:25 UTC 2022

- 30 check with cluster monitoring
 => YARN logs showing Cannot allocate memory after
 => CPU Utilization for master ~88% & cannot login XD
 => Some jobs that started before peak completed
 => Others had various of collections of work done
 => Others crashed during S3 download_file operation/extraction
 => Apps around index 20 not submitted insufficient resources

Tue  1 Nov 20:16:00 UTC 2022


- 2/3 were done by Tue  1 Nov 20:13:42 UTC 2022
 => Took a few mins for cluster monitoring to update
 => Jobs got 6 containers, 3 got 1
 => Avail memory ~30MB, load ~15%

Tue  1 Nov 20:09:00 UTC 2022
[1] 13739
13 audio-job-1.txt
[2] 14397
13 audio-job-2.txt
[3] 15749
13 audio-job-3.txt


==> audio-job-1.txt <==
22/11/01 20:10:42 INFO Client: Application report for application_1667324961020_0009 (state: RUNNING)
22/11/01 20:10:43 INFO Client: Application report for application_1667324961020_0009 (state: RUNNING)
22/11/01 20:10:44 INFO Client: Application report for application_1667324961020_0009 (state: RUNNING)

==> audio-job-2.txt <==
22/11/01 20:10:42 INFO Client: Application report for application_1667324961020_0010 (state: RUNNING)
22/11/01 20:10:43 INFO Client: Application report for application_1667324961020_0010 (state: RUNNING)
22/11/01 20:10:44 INFO Client: Application report for application_1667324961020_0010 (state: RUNNING)

==> audio-job-3.txt <==
22/11/01 20:10:42 INFO Client: Application report for application_1667324961020_0011 (state: RUNNING)
22/11/01 20:10:43 INFO Client: Application report for application_1667324961020_0011 (state: RUNNING)
22/11/01 20:10:44 INFO Client: Application report for application_1667324961020_0011 (state: RUNNING)


'''



#################################
#################################
# 
# Test as Step
# 
#################################
#################################


# Submit
aws emr add-steps \
  --region "eu-west-1" \
  --cluster-id "j-3NTNOBUMJUX8K" \
  --steps file:///home/ec2-user/example-step.json



# application_1667383378826_0001
aws emr describe-step \
  --region "eu-west-1" \
  --cluster-id "j-3NTNOBUMJUX8K" \
  --step-id "s-10B5DTTSDO9Z4" \
  --query 'Step.Status'

'''

- Submitted & completed ok, stdout not available though
  => Steps are a nice way to submit work onto a private cluster
      => Logs, status etc accesible outside network
      => Mega-plus if customer struggles with proxying requests to application servers
      => Step logs from emr console cannot be refreshed
  => Old aws-cli version does not have execution-role-arn arg
  => Stays running after ~2mins

{
    "StepIds": [
        "s-3APQ3DHWP0HNG"
    ]
}


{
    "Timeline": {
        "CreationDateTime": 1667385130.135, 
        "StartDateTime": 1667385161.445
    }, 
    "State": "RUNNING", 
    "StateChangeReason": {}
}

'''


# Submit a few
for i in $(seq 10)
  do
  aws emr add-steps --region "eu-west-1" --cluster-id "j-3NTNOBUMJUX8K" --steps file:///home/ec2-user/example-step.json
done

'''

- 5 was fine, trying 10

Does indeed hault, but not so much to bring the head nodeq down
  => Free memory falls to ~140MB

WARN YarnClusterScheduler: Initial job has not accepted any resources; check your cluster UI to ensure that workers are registered and ha
ve sufficient resources


free -m
              total        used        free      shared  buff/cache   available
Mem:          15029       11548         139           0        3341        3164
Swap:             0           0           0

'''