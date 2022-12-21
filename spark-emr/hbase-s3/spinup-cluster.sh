aws emr create-cluster \
  --region "eu-west-1" \
  --applications Name=Spark Name=Hive Name=Ganglia Name=HBase Name=Zookeeper \
  --tags 'name=emr-tf-cluster' 'role=EMR_DefaultRole' \
  --bootstrap-actions Path="s3://band-cloud-audio-validation/cluster/install-audio-val.sh" \
  --configurations "file:///home/ec2-user/hbase-config.json" \
  --scale-down-behavior TERMINATE_AT_TASK_COMPLETION \
  --ebs-root-volume-size 40 \
  --ec2-attributes '{"KeyName": "emrKey",
      "AdditionalSlaveSecurityGroups": [""],
      "InstanceProfile": "arn:aws:iam::986224559876:instance-profile/spark-emr-profile",
      "ServiceAccessSecurityGroup": "sg-0b2b66b607001bb78",
      "SubnetId": "subnet-0f08469642efb1491",
      "EmrManagedSlaveSecurityGroup": "sg-069eb2ad68f473519",
      "EmrManagedMasterSecurityGroup": "sg-0d90ffb7814a100ee",
      "AdditionalMasterSecurityGroups": [""]}' \
  --service-role "arn:aws:iam::986224559876:role/sparkClusterRole" \
  --release-label "emr-6.8.0" \
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
        "InstanceType":"c5a.16xlarge",
        "Name":"HBase Cluster-S3"
    }]'