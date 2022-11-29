
aws emr create-cluster \
  --region "eu-west-1" \
  --applications Name=Spark Name=Hive Name=Ganglia Name=Zeppelin Name=Hue Name=Livy \
  --tags 'Name=BS-Package-Tester-Cluster-Fix' 'role=EMR_DefaultRole' \
  --bootstrap-actions Path="s3://band-cloud-audio-validation/cluster/install-scenarioRep.sh" \
  --scale-down-behavior TERMINATE_AT_TASK_COMPLETION \
  --ebs-root-volume-size 40 \
  --ec2-attributes '{"KeyName":"emrKey",
      "AdditionalSlaveSecurityGroups":[""],
      "InstanceProfile":"arn:aws:iam::986224559876:instance-profile/spark-emr-profile",
      "SubnetId":"subnet-0aa75b7838d570e14",
      "EmrManagedSlaveSecurityGroup":"sg-0619575e7442b0175",
      "EmrManagedMasterSecurityGroup":"sg-0ba58fe9e6975e460",
      "ServiceAccessSecurityGroup":"sg-09191bc8746af02ab",
      "AdditionalMasterSecurityGroups":[""]}' \
  --service-role "arn:aws:iam::986224559876:role/sparkClusterRole" \
  --release-label "emr-6.7.0" \
  --log-uri 's3://bk-spark-cluster-tf/spark/' \
  --name 'BS-Package-Tester-Cluster-Fix' \
  --instance-groups '[
      { "InstanceCount":3,
        "EbsConfiguration":{
          "EbsBlockDeviceConfigs":[
            {"VolumeSpecification":{
              "SizeInGB":40,"VolumeType":"gp2"
            },
            "VolumesPerInstance":1}
            ]
          },
        "InstanceGroupType":"CORE",
        "InstanceType":"m4.large",
        "Name":"TF-EMR-Core-Group"
      },
      { "InstanceCount":3,
      "EbsConfiguration":{
        "EbsBlockDeviceConfigs":[
          {"VolumeSpecification":{
            "SizeInGB":40,
            "VolumeType":"gp2"
          },
        "VolumesPerInstance":1}
      ]},
      "InstanceGroupType":"TASK",
      "InstanceType":"m1.xlarge",
      "Name":"TF-EMR-Task-Group"},
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
        "InstanceType":"m3.xlarge",
        "Name":"TF-EMR-Master-Group"
    }]'