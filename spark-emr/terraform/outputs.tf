##############################################################
##############################################################
# 
# Useful Outputs
# 
##############################################################
##############################################################


# Cluster name
output "cluster-name" {
    value = aws_emr_cluster.spark-cluster.name
    description = "Name of cluster"
}

# Cluster name
output "cluster-id" {
    value = aws_emr_cluster.spark-cluster.id
    description = "Cluster ID"
}

# Cluster head node
output "head-node" {
    description = "DNS of Head node"
    value = aws_emr_cluster.spark-cluster.master_public_dns
}

# Cluster logging
output "cluster-loggingBucket" {
    value = aws_emr_cluster.spark-cluster.log_uri
    description = "Logging Bucket"
}