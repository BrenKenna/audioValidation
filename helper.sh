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


