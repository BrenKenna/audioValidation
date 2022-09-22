###################################################
###################################################
#
# Module to hold common variables
#
# Gradually build on the tutorial and see how
#  to put worker nodes on private network
# 
###################################################
###################################################

# Network config as object
variable "cluster-network" {
    description = "Object to hold network configuration for the cluster"
    type = object({

        # Shared VPC settings
        vpcName = string
        cidrBlock = string
        region = string
        igw_name = string

        # One network for head node
        #   another for workers
        az1_subnets = object({
            availZone = string 
            head = string
            worker = string
        })

        /*

        # Notion of high avail could be nice
        #   ignore for now though
        az2_subnets = object({
            availZone = string 
            head = string
            worker = string
        })
        */
    })

    # Values for object
    default = {
        cidrBlock = "192.168.0.0/16"
        region = "eu-west-1"
        vpcName = "cluster-VPC"
        igw_name = "clusterIGW"
    
        # For eu-west-1a
        az1_subnets = {
            "availZone": "eu-west-1a",
            "head": "192.168.1.0/24",
            "worker": "192.168.2.0/24"
        }

        /*
        az2_subnets = {
            "availZone": "eu-west-1b",
            "head": "192.168.3.0/24",
            "worker": "192.168.4.0/24"
        }
        */
    }
}


# General config
variable "cluster-general" {
    description = "Object to hold general configurations for the cluster"
    type = object({
        bucketName = string
        bucketACL = string
        region = string
        key = string
        loggingUri = string
    })

    default = {
        bucketName = "spark-cluster-tf"
        bucketACL = "private"
        region = "eu-west-1"
        key = "emr-key"
        loggingUri = "s3://spark-cluster-tf/spark/"
    }
}


# Instance types
variable "cluster-instances" {
    description = "Object to hold cluster instance types"
    type = object({

        # Instance type
        headType = string
        workerType = string
        taskType = string

        # Cluster size
        headCount = number
        workerCount = number
        taskCount = number
    })

    default = {
        headType = "m3.xlarge"
        workerType = "m4.large"
        taskType = "m1.xlarge"
        headCount = 1
        workerCount = 2
        taskCount = 2
    }
}