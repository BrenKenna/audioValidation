##########################################################
##########################################################
# 
# Cloud provider
#
##########################################################
##########################################################

# Cloud provider
provider "aws" {
    region = "${var.cluster-network.region}"
    assume_role {
        role_arn = "${var.auth-tf.roleArn}"
        session_name = "${var.auth-tf.sessionName}"
    }
}