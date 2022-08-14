// Creates EMR cluster
resource "aws_emr_cluster" "emr_cluster" {
  name       = "${var.namespace}-${var.project}-${var.stage}-emr"
  depends_on = [aws_key_pair.emr_key_pair, module.vpc, aws_iam_instance_profile.iam_instance_profile_spark]

  release_label = var.emr_release
  applications  = var.emr_applications
  service_role  = var.emr_roles.service

  termination_protection            = false
  keep_job_flow_alive_when_no_steps = true
  configurations_json               = file("configurations.json")
  log_uri                           = "s3://${var.s3_bucket}/${var.s3_log_uri}"

  ec2_attributes {
    subnet_id                         = element(aws_subnet.public_subnet.*.id, 1)
    emr_managed_master_security_group = aws_security_group.security_group_spark.id
    emr_managed_slave_security_group  = aws_security_group.security_group_spark.id
    instance_profile                  = aws_iam_instance_profile.iam_instance_profile_spark.arn
    key_name                          = aws_key_pair.emr_key_pair.key_name
  }

  master_instance_group {
    instance_type = var.emr_master_instance_type
  }

  core_instance_group {
    instance_type  = var.emr_core_instance.type
    instance_count = var.emr_core_instance.count
  }

  /*
  bootstrap_action {
    path = "s3://${var.s3_bucket}/${var.emr_bootstrap.key}"
    name = var.emr_bootstrap.name
    args = var.emr_bootstrap.args
  }
  */

  step {
    action_on_failure = "CONTINUE"
    name              = "Spark ETL Pipeline Script"

    hadoop_jar_step {
      jar  = "command-runner.jar"
      args = [
        "spark-submit",
        "--master", "yarn",
        "--deploy-mode", "cluster",
        "--conf", "spark.dynamicAllocation.enabled=true",
        "--conf", "spark.shuffle.service.enabled=true",
        "s3a://${var.s3_bucket}/${var.s3_app_files.target}/etl/etl.py",
        "--py-files",
        "s3a://${var.s3_bucket}/${var.s3_app_files.target}/etl/config.py",
        "s3a://${var.s3_bucket}/${var.s3_app_files.target}/etl/metadata.py",
      ]
    }
  }

  lifecycle {
    ignore_changes = [step]
  }

  tags = merge(local.common_tags, { category = "processing", resource = "spark" })
}

resource "aws_iam_instance_profile" "iam_instance_profile_spark" {
  name = "${var.namespace}-${var.project}-${var.stage}-iam-instance-profile"
  role = var.emr_roles.instance
}