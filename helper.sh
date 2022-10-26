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


#######################################
#######################################
# 
# 2). Install audio software
# 
#######################################
#######################################

# Install via pip
pip install librosa matplotlib numpy pandas scikit-learn

# Via cona dependencies: numba could throw weird error, think this >0.53 or something
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
#  => Move onto debugging run app
#  => Public cluster
#  => Console logs post cluster spin-up
#  => S3 logs post sping-up
#  => Logs post:
#      a). CPU Load
#      b). Storage-FS
#      c). Storage-HDFS
#      d). Stopping nodes
# 
###########################################
###########################################



######################################
# 
# a). Debug Internet Access
#  => Cluster spin-up >1hr
#  => Should be 15-20mins
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


"""

# Note on removing IGW while Nat is attached

"""

- IGW cannot be dependent on NAT

Error: error waiting for EC2 NAT Gateway (nat-0e21891f82005a9b7) create: unexpected state 'failed', wanted target 'available'. last error: Gateway.NotAttached: Network vpc-0f5754232efa349a2 has no Internet gateway attached

"""