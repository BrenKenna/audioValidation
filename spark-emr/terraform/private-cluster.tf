################################################################################
################################################################################
# 
# Spinup Cluster:
#  -> Changed version from 5.9 to 6.7
#  -> Version 6.7 uses python3
#
# Comeback to multinode master plans
#  To install Hive on an Amazon EMR cluster with multiple master nodes,
# you must first configure an external metastore in hive-site.
#
# New error after 1hr
#  │ Error: error waiting for EMR Cluster (j-1XHWODSTSREGC) to create: unexpected state 'TERMINATING', wanted target 'RUNNING, WAITING'. last error:
# INTERNAL_ERROR: Failed to start the job flow due to an internal error
#
################################################################################
################################################################################

# Spinup cluster
resource "aws_emr_cluster" "spark-cluster" {

   # Cluster data
    name = "EMR Terraform Cluster"
    release_label = "emr-6.7.0"
    applications = [
        "Ganglia",
        "Spark",
        "Livy",
        "Zeppelin",
        "Hive",
        "Sqoop",
        "Hue"
    ]
    service_role = "${aws_iam_role.sparkClusterRole.arn}"
    log_uri = "${var.cluster-general.loggingUri}"
    tags = {
        name = "emr-tf-cluster"
        role = "EMR_DefaultRole"
    }
    ebs_root_volume_size = 40

    bootstrap_action {
        path = "s3://band-cloud-audio-validation/cluster/install-audio-val.sh"
        name = "Install-Audio-Validator"
        /*
        args = [
            "instance.isMaster=true",
            "echo running on master node"
        ]
        */
    }

    # Configure ec2 instance network, keys, auth & sec
    ec2_attributes {
        instance_profile = "${aws_iam_instance_profile.spark-emr-profile.arn}"
        key_name = "${var.cluster-general.key}"
        subnet_id = "${aws_subnet.cluster_subnet.id}"
        emr_managed_master_security_group = "${aws_security_group.cluster-headnode-sg.id}"
        emr_managed_slave_security_group = "${aws_security_group.cluster-workernode-sg.id}"
        service_access_security_group = "${aws_security_group.service-access-sg.id}"
    }
 
    # Configure head instance(s
    master_instance_group {
        name = "TF-EMR-Master-Group"
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
        name = "TF-EMR-Core-Group"
        instance_type = "${var.cluster-instances.workerType}"
        instance_count = "${var.cluster-instances.workerCount}"

        ebs_config {
            size = "40"
            type = "gp2"
            volumes_per_instance = 1
        }
    }

    # Depends on route table
    depends_on = [ 
        aws_route_table_association.cluster-rta,
        aws_security_group.cluster-headnode-sg,
        aws_security_group.cluster-workernode-sg,
        aws_security_group.service-access-sg,
        aws_iam_instance_profile.spark-emr-profile
    ]
    # depends_on = [ aws_s3_bucket.cluster-bucket ]
}


# Configure task group
resource "aws_emr_instance_group" "task_group" {
    cluster_id = "${aws_emr_cluster.spark-cluster.id}"
    instance_count = var.cluster-instances.taskCount
    instance_type = "${var.cluster-instances.taskType}"
    name = "TF-EMR-Task-Group"
    # depends_on = [ aws_emr_cluster.spark-cluster ]
    ebs_config {
        size = "40"
        type = "gp2"
        volumes_per_instance = 1
    }
}


# Bastion host
resource "aws_instance" "bastion-server" {
    ami = "${var.cluster-general.amiDebug}"
    instance_type = "t3.large"
    key_name = "${var.cluster-general.key}"
    security_groups = [ "${aws_security_group.bastion-sg.id}" ]
    associate_public_ip_address = true
    subnet_id = "${aws_subnet.bastion_subnet.id}"
    tags = {
        Name = "bastion-server"
    }
}