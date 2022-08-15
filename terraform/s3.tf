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

// Uploads EMR application files
resource "aws_s3_object" "emr_app_files" {
  depends_on = [aws_s3_bucket_acl.emr_bucket_acl]

  bucket   = aws_s3_bucket.emr_bucket.id
  for_each = toset(var.s3_app_files.source)

  key    = "${var.s3_app_files.target}/${basename(each.value)}"
  source = each.value
}

// Uploads EMR bootstrap script
/*
resource "aws_s3_object" "emr_bootstrap_script" {
  depends_on = [aws_s3_bucket_acl.emr_bucket_acl]
  bucket     = aws_s3_bucket.emr_bucket.id
  key        = var.emr_bootstrap.key
  source     = var.emr_bootstrap.source
}
*/