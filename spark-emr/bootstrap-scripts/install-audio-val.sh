#!/bin/bash

# Install core packages
sudo yum install -y libsndfile.x86_64 libsndfile-utils.x86_64 libsndfile-devel.x86_64 nfs-utils
sudo pip3 install --target "/usr/lib/python3.7/site-packages/" pysoundfile
sudo pip3 install --target "/usr/lib/python3.7/site-packages/" librosa matplotlib numpy pandas scikit-learn
sudo pip3 install --target "/usr/lib/python3.7/site-packages/" boto3
cd /usr/local/lib/python3.7/site-packages/ && sudo rm -fr dateutil/
#python -c 'import librosa'


# Install the audioValidator
sudo yum install -y git
git clone --recursive https://github.com/BrenKenna/audioValidation.git
cd audioValidation
rm -fr Figs/ spark-emr/ helper.sh README.md links.txt
sudo mv audioValidator/ /usr/lib/python3.7/site-packages/
python --version
pip3 --version


#
# Handle numba cache dire
#  - Probably cause issues down the line
#  https://github.com/numba/numba/issues/7883
#  Alternative = https://github.com/librosa/librosa/issues/1013
mkdir -m 777 /tmp/NUMBA_CACHE_DIR

#
# Holding on to see installation ocurred
# cd ~
# rm -fr audioValidation/
# 

# Test imports: Can instantiate compartor
# sudo su; cd /usr/lib/python3.7/site-packages/audioValidator/comparator
# python -c '
## from audioValidator.comparator import comparator as avc
## audioVal = avc.AudioValComparator()
## audioVal.loadTrainingSet()
## print(audioVal.data)
# '

# 
# Mount EFS
#  => Writes test data just fine (nifty to know)
#  => Creates standard wal directories just fine
#  => Sturggles thereafter because it does not "suitable capabilities for output streams".
# 
# efs_dns="fs-01d7ded11f3a12725.efs.eu-west-1.amazonaws.com"
# mkdir -p /mnt/efs-wal
# sudo mount \
#    -t nfs \
#    -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport \
#    ${efs_dns}:/ \
#    /mnt/efs-wal
# sudo chmod go+rw /mnt/efs-wal
# randN=$(( ( RANDOM % 10 ) + 1 )) 
# seq 3 > /mnt/efs-wal/test-${randN}.txt
# 