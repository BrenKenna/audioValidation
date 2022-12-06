###############################################################
###############################################################
# 
# Terraforming Spark Cluster
# 
#
# References:
# 
# https://intothedepthsofdataengineering.wordpress.com/2017/11/19/terraforming-a-spark-cluster-on-amazon/
#
###############################################################
###############################################################

# 
# Configure login
# mv ~/Downloads/emr-key.pem ~/Documents/Repo/spark-emr/
# chmod 600 emr-key.pem
# ssh -i emr-key.pem ec2-user@
# 

# Copy key
scp -pi ____.pem ____.pem USER@HOST

# Install terraform etc
sudo su
yum update -y
yum install -y yum-utils
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
yum -y install terraform
yum update -y 


# Setup working dir
mkdir -p ~/spark-terraform && cd ~/spark-terraform
terraform init


# Plan resources
terraform plan


# Create resources
terraform apply


# Login to head node: Copy key
scp -pi emr-key.pem emr-key.pem hadoop@____:~/.ssh/
ssh -i emr-key.pem hadoop@____



##########################
# 
# Via Assumed Role
# 
##########################


# Setup working dir
mkdir -p ~/ec2-terraform && cd ~/ec2-terraform
terraform init

# Sanity check with an IAM role comparing to aws cli
terraform apply
aws ec2 run-instances \
    --image-id ____ \
    --instance-type t2.micro \
    --subnet-id ____ \
    --key-name emr-key \
    --region eu-west-1 \
    --security-group-ids ____ \
    --count 1


"""

- Terraform does not either public/private ami

Error: creating EC2 Instance: UnauthorizedOperation: You are not authorized to perform this operation


- Client works fine
{
    'Instance'
    ...
    ...
}

"""

##################################################
##################################################
# 
# Scope Out the Cluster
# 
# https://spark.apache.org/docs/latest/cluster-overview.html
# 
##################################################
##################################################


####################################
####################################
#
# 1. User Interfaces
# 
#  - Fine but the hue & yar 302
# 
####################################
####################################


# Hadoop name node: Hadoop Admin
curl -i http://ec2-34-247-254-141.eu-west-1.compute.amazonaws.com:50070/


# Spark history
curl -i http://ec2-34-246-223-212.eu-west-1.compute.amazonaws.com:18080/


# Ganglia
curl -i http://ec2-34-247-254-141.eu-west-1.compute.amazonaws.com/ganglia/


# Zepplin
curl -i http://ec2-34-247-254-141.eu-west-1.compute.amazonaws.com:8890/


# Hue: 302
curl -i http://ec2-34-247-254-141.eu-west-1.compute.amazonaws.com:8888/


# Resource manager: 302
curl -i http://ec2-34-247-254-141.eu-west-1.compute.amazonaws.com:8088/


# Task groups: HDFS Data Node, Node Manager
ssh -i ~/.ssh/erm-key.pem hadoop@192.168.1.31
curl -i http://ec2-63-32-118-138.eu-west-1.compute.amazonaws.com:50075/
curl -i http://ec2-63-32-118-138.eu-west-1.compute.amazonaws.com:8042/




####################################
####################################
#
# 2. Shells
# 
#  - All fine
# 
####################################
####################################

# Test shells
spark-shell # Scala
spark-shell --master yarn --deploy-mode client # Also scala,  Alternative mode = cluster
pyspark
sparkR



##############################################
##############################################
#
# 3. Job Scheduling
# 
# References:
# https://spark.apache.org/docs/latest/job-scheduling.html
# https://sparkbyexamples.com/spark/spark-submit-command/
# 
# 
# 
# 
##############################################
##############################################

##############################
# 
# Example
# 
# - Probably wont use conf too oftenr
# 
##############################

# Template
spark-submit \
    --master yarn|spark://HOST:PORT \
    --deploy-mode client|cluster \
    --conf <key<=<value> \
    --driver-memory <value>g \
    --executor-memory <value>g \
    --executor-cores <number of cores>  \
    --jars  <comma separated dependencies>
    --class <main-class> \
    <application-jar> \
    [application-arguments]


# Simple python template
spark-submit --master yarn --deploy-mode cluster testing.py

"""

- Apps are little different than used to
- Basically use cluster to manage big for loop
- Analysts run sessions, not big long process
- Likes PiCaS/PyAnamo better for old work
    => Deploy an app at veritcal + horizontal scale

"""

#################################################
# 
# Endpoint Tests
# 
#################################################


# Spin up cluster with s3 endpoint
bash spinup-cluster.sh

'''
{
    "ClusterId": "j-WX5419AMREWO", 
    "ClusterArn": "arn:aws:elasticmapreduce:eu-west-1:986224559876:cluster/j-WX5419AMREWO"
}
'''


#
#
# Test distruptions to communication to KMS
#  - InstanceId = i-04556a7553c662969
#  - 192.168.2.163
#
curl -I https://www.amazon.co.uk

'''
HTTP/2 503 
content-type: text/html
content-length: 7053
server: Server
date: Thu, 01 Dec 2022 10:42:11 GMT
x-amz-rid: W4DZHVY2WCAR43HAKHX7
vary: Content-Type,Accept-Encoding,User-Agent
strict-transport-security: max-age=47474747; includeSubDomains; preload
x-cache: Error from cloudfront
via: 1.1 145b7e87a6273078e52d178985ceaa5e.cloudfront.net (CloudFront)
x-amz-cf-pop: DUB56-P1
x-amz-cf-id: G980shePZXtubPa6IvwcPohSepsTIgpirGIbG3AU5hq_tdcakFE_OA==
'''


# List keys can access fine
aws kms list-keys --region "eu-west-1" --query 'Keys[*].KeyId' | wc -l

'''
10
'''

# Added KMS endpoint with mis-configured SG
aws kms list-keys \
    --debug \
    --region "eu-west-1" \
    --query 'Keys[*].KeyId' | wc -l

'''
Connection hangs

2022-12-01 10:59:51,859 - MainThread - urllib3.connectionpool - DEBUG - Starting new HTTPS connection (1): kms.eu-west-1.amazonaws.com:443
2022-12-01 11:00:51,919 - MainThread - botocore.endpoint - DEBUG - Exception received when sending HTTP request.
2022-12-01 11:00:51,964 - MainThread - botocore.hooks - DEBUG - Event needs-retry.kms.ListKeys: calling handler <botocore.retryhandler.RetryHandler object at 0x7f7fb52619d0>
2022-12-01 11:00:51,964 - MainThread - botocore.retryhandler - DEBUG - retry needed, retryable exception caught: Connect timeout on endpoint URL: "https://kms.eu-west-1.amazonaws.com/"

'''


# After allowing inbound HTTPs from master
aws kms list-keys \
    --debug \
    --region "eu-west-1" \
    --query 'Keys[*].KeyId' | wc -l

"""

2022-12-01 11:13:59,925 - MainThread - awscli.clidriver - DEBUG - Arguments entered to CLI: ['kms', 'list-keys', '--debug', '--region', 'eu-west-1', '--query', 'Keys[*].KeyId']
2022-12-01 11:13:59,925 - MainThread - botocore.hooks - DEBUG - Event session-initialized: calling handler <function add_scalar_parsers at 0x7f26aed44550>
2022-12-01 11:13:59,925 - MainThread - botocore.hooks - DEBUG - Event session-initialized: calling handler <function register_uri_param_handler at 0x7f26afc4acd0>
2022-12-01 11:13:59,926 - MainThread - botocore.hooks - DEBUG - Event session-initialized: calling handler <function inject_assume_role_provider_cache at 0x7f26afbaf0d0>
2022-12-01 11:13:59,927 - MainThread - botocore.hooks - DEBUG - Event session-initialized: calling handler <function attach_history_handler at 0x7f26af0c7950>

"""