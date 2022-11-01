#!/bin/bash

# Install core packages
sudo yum install -y libsndfile.x86_64 libsndfile-utils.x86_64 libsndfile-devel.x86_64
sudo pip3 install pysoundfile
sudo pip3 install librosa matplotlib numpy pandas scikit-learn
sudo pip3 install boto3
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

