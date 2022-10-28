
aws emr create-cluster \
  --region "eu-west-1" \
  --applications Name=Spark Name=Hive Name=Ganglia Name=Zeppelin Name=Hue \
  --tags 'name=emr-tf-cluster' 'role=EMR_DefaultRole' \
  --bootstrap-actions Path="s3://band-cloud-audio-validation/cluster/install-audio-val.sh" \
  --scale-down-behavior TERMINATE_AT_TASK_COMPLETION \
  --ebs-root-volume-size 40 \
  --ec2-attributes '{"KeyName":"emrKey",
      "AdditionalSlaveSecurityGroups":[""],
      "InstanceProfile":"arn:aws:iam::986224559876:instance-profile/spark-emr-profile",
      "ServiceAccessSecurityGroup":"sg-005f951cb60452c81",
      "SubnetId":"subnet-0987ec53caf15c42d",
      "EmrManagedSlaveSecurityGroup":"sg-07052b44e77b91f58",
      "EmrManagedMasterSecurityGroup":"sg-0333d9dce12f066db",
      "AdditionalMasterSecurityGroups":[""]}' \
  --service-role "arn:aws:iam::986224559876:role/sparkClusterRole" \
  --release-label "emr-6.7.0" \
  --log-uri 's3n://bk-spark-cluster-tf/spark/' \
  --name 'EMR Terraform Cluster v2' \
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