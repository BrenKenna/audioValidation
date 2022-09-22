####################################################################
####################################################################
# 
# Configure Storage
# 
# https://intothedepthsofdataengineering.wordpress.com/2017/11/19/terraforming-a-spark-cluster-on-amazon/
# https://github.com/idealo/terraform-emr-pyspark/blob/master/modules/s3/main.tf
# 
####################################################################
####################################################################


# Create logging bucket
resource "aws_s3_bucket" "cluster-bucket" {
  bucket = "${var.cluster-general.bucketName}"
}


# Bucket ACL
resource "aws_s3_bucket_acl" "cluster-bucket" {
  bucket = aws_s3_bucket.cluster-bucket.id
  acl    = "private"
}