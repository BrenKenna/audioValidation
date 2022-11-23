#!/bin/bash


# App repo
APP_REPO="986224559876.dkr.ecr.eu-west-1.amazonaws.com/audio-validation"
sudo yum install -y docker
sudo service docker start
sudo usermod -a -G docker ec2-user


# Configure audioVal img
mkdir audioVal-Docker && cd audioVal-Docker
$(aws ecr get-login-password --region "eu-west-1" |\
    docker login --username AWS -p "${ECR_PASS}" "${APP_REPO}" )

docker build --no-cache -t audio-validator .
docker tag audio-validator:latest ${APP_REPO}:latest
docker push ${APP_REPO}:latest


# Debug build errors if needs be
run -it audio-validator

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


# 