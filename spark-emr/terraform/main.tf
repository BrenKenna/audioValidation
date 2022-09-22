##########################################################
##########################################################
# 
# Spinup Cluster:
#  -> Changed version from 5.9 to 6.7
#  -> Version 6.7 uses python3
#
##########################################################
##########################################################

# Spinup cluster
resource "aws_emr_cluster" "spark-cluster" {

   # Cluster data
    name = "EMR Terraform Cluster"
    release_label = "emr-6.7.0"
    applications = [ "Ganglia", "Spark", "Zeppelin", "Hive", "Hue" ]
    service_role = "${aws_iam_role.sparkClusterRole.arn}"
    log_uri = "${var.cluster-general.loggingUri}"
    tags = {
        name = "emr-tf-cluster"
        role = "EMR_DefaultRole"
    }
    # depends_on = [ aws_s3_bucket.cluster-bucket ]

    # Configure ec2 instance network, keys, auth & sec
    ec2_attributes {
        instance_profile = "${aws_iam_instance_profile.spark-emr-profile.arn}"
        key_name = "${var.cluster-general.key}"
        subnet_id = "${aws_subnet.cluster_subnet.id}"
        emr_managed_master_security_group = "${aws_security_group.headnode-sg.id}"
        emr_managed_slave_security_group = "${aws_security_group.workernode-sg.id}"
    }
 
    # Configure head instance(s
    master_instance_group {
        instance_type = "${var.cluster-instances.headType}"
        instance_count = "${var.cluster-instances.headCount}"

        ebs_config {
            size = "40"
            type = "gp2"
            volumes_per_instance = 1
        }
    }

    # Configure worker node
    core_instance_group {
        instance_type = "${var.cluster-instances.workerType}"
        instance_count = "${var.cluster-instances.workerCount}"

        ebs_config {
            size = "40"
            type = "gp2"
            volumes_per_instance = 1
        }
    }
}


# Configure task group
resource "aws_emr_instance_group" "task_group" {
    cluster_id = "${aws_emr_cluster.spark-cluster.id}"
    instance_count = var.cluster-instances.taskCount
    instance_type = "${var.cluster-instances.taskType}"
    name = "Task Group"
    depends_on = [ aws_emr_cluster.spark-cluster ]
    ebs_config {
        size = "40"
        type = "gp2"
        volumes_per_instance = 1
    }
}