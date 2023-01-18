aws emr create-cluster \
  --region "eu-west-1" \
  --applications Name=Spark Name=Hive Name=Ganglia Name=Zeppelin Name=Hue Name=Livy \
  --tags 'name=emr-tf-cluster' 'role=EMR_DefaultRole' \
  --bootstrap-actions Path="s3://band-cloud-audio-validation/cluster/install-audio-val.sh" \
  --scale-down-behavior TERMINATE_AT_TASK_COMPLETION \
  --ebs-root-volume-size 40 \
  --ec2-attributes '{"KeyName": "emrKey",
      "AdditionalSlaveSecurityGroups": [""],
      "InstanceProfile": "arn:aws:iam::986224559876:instance-profile/spark-emr-profile",
      "ServiceAccessSecurityGroup": "sg-02f42e8bca646c3be",
      "SubnetId": "subnet-004e9baf258b8f713",
      "EmrManagedSlaveSecurityGroup": "sg-0bb62de0a98f529e0",
      "EmrManagedMasterSecurityGroup": "sg-04e692db7fc863383",
      "AdditionalMasterSecurityGroups": [""]}' \
  --service-role "arn:aws:iam::986224559876:role/sparkClusterRole" \
  --release-label "emr-6.7.0" \
  --log-uri 's3n://bk-spark-cluster-tf/spark/' \
  --name 'HBase Cluster-S3' \
  --instance-groups '[
      { "InstanceCount": 8,
      "EbsConfiguration":{
        "EbsBlockDeviceConfigs":[
          {"VolumeSpecification":{
            "SizeInGB":40,
            "VolumeType":"gp2"
          },
        "VolumesPerInstance":1}
      ]},
      "InstanceGroupType":"CORE",
      "InstanceType":"r5dn.2xlarge",
      "Name":"Core-2"},
    { "InstanceCount":1,
      "EbsConfiguration":{
        "EbsBlockDeviceConfigs":[
          {
            "VolumeSpecification":{
              "SizeInGB":40,
              "VolumeType":"gp2"
            },
          "VolumesPerInstance":1}
        ]},
        "InstanceGroupType":"MASTER",
        "InstanceType":"i2.xlarge",
        "Name":"TF-EMR-Master-Group"
    }]'
