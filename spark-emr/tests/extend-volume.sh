#!/bin/bash

# Fill up space
fallocate -l 24GB /mnt/test.img
df -h

'''
Filesystem      Size  Used Avail Use% Mounted on
devtmpfs        3.9G     0  3.9G   0% /dev
tmpfs           3.9G     0  3.9G   0% /dev/shm
tmpfs           3.9G  540K  3.9G   1% /run
tmpfs           3.9G     0  3.9G   0% /sys/fs/cgroup
/dev/xvda1       40G  7.5G   33G  19% /
/dev/xvdb1      5.0G   75M  5.0G   2% /emr
/dev/xvdb2       35G   26G  9.1G  75% /mnt
tmpfs           798M     0  798M   0% /run/user/995
tmpfs           798M     0  798M   0% /run/user/0
'''


# .342 * 40 = 13.68
sudo lsblk
NAME    MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
xvda    202:0    0  40G  0 disk 
└─xvda1 202:1    0  40G  0 part /
xvdb    202:16   0  54G  0 disk 
├─xvdb1 202:17   0   5G  0 part /emr
└─xvdb2 202:18   0  35G  0 part /mnt


# Goal is to find target to extend
instanceID=$(curl http://169.254.169.254/latest/meta-data/instance-id)
rootVol=$(curl http://169.254.169.254/latest/meta-data/block-device-mapping/root)
ebsVol=$(curl http://169.254.169.254/latest/meta-data/block-device-mapping/ebs1 | awk '{ print "/dev/"$1}')
aws ec2 describe-instances \
    --region eu-west-1 \
    --instance-ids "${instanceID}" \
    --query "Reservations[0].Instances[0].BlockDeviceMappings[*]" \
    | jq ".[] | select(.DeviceName == \"${ebsVol}\")" > ebsVol.txt

aws ec2 describe-instances \
    --region eu-west-1 \
    --instance-ids "${instanceID}" \
    --query "Reservations[0].Instances[0].BlockDeviceMappings[*]" \
    | jq ".[] | select(.DeviceName == \"${rootVol}\")" > rootVol.txt



# Want to extend volume by 20%
# Noticed that HDFS was ~14.2% lower than N nodes * GB per Node
volumeId=$(cat ebsVol.txt | jq '.Ebs.VolumeId' | sed 's/\"//g')
currentVolSize=$(
aws ec2 describe-volumes \
    --region "eu-west-1" \
    --volume-ids "${volumeId}" \
    --query "Volumes[0].Size" \
)
newVolSize=$(echo $currentVolSize | awk ' { printf int($1 + ($1 * .342))}')

aws ec2 modify-volume \
    --region "eu-west-1" \
    --volume-id "${volumeId}" \
    --size "${newVolSize}"


# Grow target partition
volName=$(lsblk $ebsVol | awk 'NR == 2 {print $1}')
driverPart="mnt"
partNumber=$(lsblk $ebsVol | grep "${driverPart}" | grep -wo "${volName}[0-9]" | sed "s/${volName}//g")
sudo growpart ${volName} ${partNumber}