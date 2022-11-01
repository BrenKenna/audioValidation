
aws emr create-cluster \
  --region "eu-west-1" \
  --applications Name=Spark Name=Hive Name=Ganglia Name=Zeppelin Name=Hue Name=Livy \
  --tags 'name=emr-tf-cluster' 'role=EMR_DefaultRole' \
  --bootstrap-actions Path="s3://band-cloud-audio-validation/cluster/install-audio-val.sh" \
  --scale-down-behavior TERMINATE_AT_TASK_COMPLETION \
  --ebs-root-volume-size 40 \
  --ec2-attributes '{"KeyName":"emrKey",
      "AdditionalSlaveSecurityGroups":[""],
      "InstanceProfile":"arn:aws:iam::986224559876:instance-profile/spark-emr-profile",
      "ServiceAccessSecurityGroup":"sg-07808dd42b930346b",
      "SubnetId":"subnet-013784b3270cfe26f",
      "EmrManagedSlaveSecurityGroup":"sg-0c6f98eebbe259cf3",
      "EmrManagedMasterSecurityGroup":"sg-05b2adfbf6ae9d42c",
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
