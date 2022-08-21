// Creates S3 bucket
resource "aws_s3_bucket" "emr_bucket" {
  bucket        = var.s3_bucket
  force_destroy = true

  tags = merge(local.common_tags, {
    category                                 = "storage",
    resource                                 = "bucket",
    service                                  = "S3"
    for-use-with-amazon-emr-managed-policies = true
  })
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

// Uploads EMR bootstrap files
resource "aws_s3_object" "emr_bootstrap_files" {
  depends_on = [aws_s3_bucket_acl.emr_bucket_acl]

  bucket   = aws_s3_bucket.emr_bucket.id
  for_each = toset(var.s3_bootstrap_files.source)

  key    = "${var.s3_bootstrap_files.target}/${basename(each.value)}"
  source = each.value
}
