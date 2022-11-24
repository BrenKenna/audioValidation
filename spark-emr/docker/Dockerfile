# Amazon Linux as OS Layer
# Spark & friends written in Java ;)
# FROM amazonlinux:latest
FROM amazoncorretto:8

# Install librosa dependencies
RUN yum update -y \
    && yum install -y yum-utils amazon-linux-extras gcc-c++ git ls tar time hostname jq
RUN yum install -y libsndfile.x86_64 libsndfile-utils.x86_64 libsndfile-devel.x86_64 python3


# Install python packages
RUN pip3 install pysoundfile boto3 matplotlib numpy pandas scikit-learn
RUN pip3 install librosa


# Fetch audioVal repo
RUN git clone --recursive https://github.com/BrenKenna/audioValidation.git && \
    cd audioValidation && \
    rm -fr Figs/ spark-emr/ helper.sh README.md links.txt && \
    mv audioValidator/ /usr/lib/python3.7/site-packages/


# Test build
RUN python3 /usr/lib/python3.7/site-packages/audioValidator/run-comparator.py --help