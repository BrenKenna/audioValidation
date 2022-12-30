aws emr create-cluster \
  --region "eu-west-1" \
  --applications Name=Spark Name=Hadoop Name=Hive Name=Livy Name=Ganglia \
  --tags 'Name=LivyTests' 'role=EMR_DefaultRole' \
  --bootstrap-actions Path="s3://band-cloud-audio-validation/cluster/install-audio-val.sh" \
  --scale-down-behavior TERMINATE_AT_TASK_COMPLETION \
  --ebs-root-volume-size 40 \
  --ec2-attributes '{"KeyName":"emrKey",
      "AdditionalSlaveSecurityGroups":[""],
      "InstanceProfile":"arn:aws:iam::986224559876:instance-profile/spark-emr-profile",
      "SubnetId":"subnet-0c94db3a0351186eb",
      "EmrManagedSlaveSecurityGroup":"sg-0348f92bfef61dc5b",
      "EmrManagedMasterSecurityGroup":"sg-098969f14afca3b56",
      "ServiceAccessSecurityGroup":"sg-0249fce32617f0e2e",
      "AdditionalMasterSecurityGroups":[""]}' \
  --service-role "arn:aws:iam::986224559876:role/sparkClusterRole" \
  --release-label "emr-6.8.0" \
  --log-uri 's3://bk-spark-cluster-tf/spark/' \
  --name 'AudioVal-Test' \
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