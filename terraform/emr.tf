resource "aws_emr_cluster" "cluster" {
  name       = "${var.namespace}-${var.project}-${var.stage}-emr"
  depends_on = [
    aws_subnet.public_subnet,
    aws_security_group.security_group_spark,
    aws_key_pair.emr_key_pair,
    aws_iam_role.emr_service_role,
    aws_iam_instance_profile.emr_ec2_profile
  ]

  release_label = var.emr_release
  applications  = var.emr_applications
  service_role  = aws_iam_role.emr_service_role.arn

  termination_protection            = false
  step_concurrency_level            = 1
  keep_job_flow_alive_when_no_steps = true
  log_uri                           = "s3://${var.s3_bucket}/${var.s3_log_uri}"

  ec2_attributes {
    subnet_id                         = element(aws_subnet.public_subnet.*.id, 0)
    emr_managed_master_security_group = aws_security_group.security_group_spark.id
    emr_managed_slave_security_group  = aws_security_group.security_group_spark.id
    instance_profile                  = aws_iam_instance_profile.emr_ec2_profile.arn
    key_name                          = aws_key_pair.emr_key_pair.key_name
  }

  master_instance_group {
    instance_type = var.emr_master_instance_type
  }

  core_instance_group {
    instance_type  = var.emr_core_instance.type
    instance_count = var.emr_core_instance.count
  }

  bootstrap_action {
    path = "s3://${var.s3_bucket}/${var.s3_bootstrap_files.target}/bootstrap.sh"
    name = "cluster-bootstrap"
    args = []
  }

  /*
  step {
    action_on_failure = "CONTINUE"
    name              = "S3DistCp Log Step"

    hadoop_jar_step {
      jar  = "command-runner.jar"
      args = [
        "s3-dist-cp",
        "--src",
        "s3://${var.s3_udacity_bucket}/log_data",
        "--dest",
        "s3://${var.s3_bucket}/application/data/bronze/logs_json",
        "--srcPrefixesFile",
        "s3://${var.s3_bucket}/application/data/prefix/log_data_prefix.txt",
        "--groupBy",
        ".*\/(log_data)/.*(\\.json)"
      ]
    }
  }

  step {
    action_on_failure = "CONTINUE"
    name              = "S3DistCp Song Step"

    hadoop_jar_step {
      jar  = "command-runner.jar"
      args = [
        "s3-dist-cp",
        "--src",
        "s3://${var.s3_udacity_bucket}/song_data",
        "--dest",
        "s3://${var.s3_bucket}/application/data/bronze/songs_json",
        "--srcPrefixesFile",
        "s3://${var.s3_bucket}/application/data/prefix/song_data_prefix.txt",
        "--groupBy",
        ".*\/(song_data)/.*(\\.json)"
      ]
    }
  }

  step {
    action_on_failure = "CONTINUE"
    name              = "Spark ETL Pipeline Step"

    hadoop_jar_step {
      jar  = "command-runner.jar"
      args = [
        "spark-submit",
        "--py-files",
        "s3://${var.s3_bucket}/${var.s3_app_files.target}/datadiver_aws_emr-0.1.0-py3-none-any.whl",
        "s3://${var.s3_bucket}/${var.s3_app_files.target}/driver.py",
        "main"
      ]
    }
  }
  */

  lifecycle {
    ignore_changes = [step]
  }

  tags = merge(local.common_tags, {
    category                                 = "processing",
    resource                                 = "spark",
    for-use-with-amazon-emr-managed-policies = true
  })
}
