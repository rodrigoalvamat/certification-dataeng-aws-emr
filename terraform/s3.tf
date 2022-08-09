// Creates S3 bucket
resource "aws_s3_bucket" "emr_bucket" {
  bucket        = var.s3_bucket
  force_destroy = true
}

// Sets S3 bucket access control list
resource "aws_s3_bucket_acl" "emr_bucket_acl" {
  depends_on = [aws_s3_bucket.emr_bucket]
  bucket     = aws_s3_bucket.emr_bucket.id
  acl        = "private"
}

// Creates EMR log folder
/*
resource "aws_s3_object" "emr_log_file" {
  depends_on = [aws_s3_bucket_acl.emr_bucket_acl]

  bucket       = aws_s3_bucket.emr_bucket.id
  key          = var.s3_log_uri
  content_type = "application/x-directory"
}
*/

// Uploads EMR sample data files
resource "aws_s3_object" "dist" {
  depends_on = [aws_s3_bucket_acl.emr_bucket_acl]

  bucket   = aws_s3_bucket.emr_bucket.id
  for_each = fileset(var.s3_data_files.source, "*")

  key    = "${var.s3_data_files.target}/${each.value}"
  source = "${var.s3_data_files.source}/${each.value}"
}

// Uploads EMR bootstrap script
resource "aws_s3_object" "emr_bootstrap_script" {
  depends_on = [aws_s3_bucket_acl.emr_bucket_acl]
  bucket     = aws_s3_bucket.emr_bucket.id
  key        = var.emr_bootstrap.key
  source     = var.emr_bootstrap.source
}