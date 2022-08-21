resource "aws_iam_role" "emr_service_role" {
  name        = "${var.namespace}-${var.project}-${var.stage}-iam-emr-role"
  description = "Default service role for EMR"

  assume_role_policy = file("./permissions/EmrDefaultRole.json")
}

resource "aws_iam_role_policy" "iam_emr_service_policy" {
  name        = "${var.namespace}-${var.project}-${var.stage}-iam-emr-service-policy"

  role   = aws_iam_role.emr_service_role.id
  policy = file("./permissions/EmrDefaultPolicyDeprecated.json")
}

resource "aws_iam_role" "emr_ec2_role" {
  name        = "${var.namespace}-${var.project}-${var.stage}-iam-emr-ec2-role"
  description = "Default role for EMR EC2"

  assume_role_policy = file("./permissions/EmrEc2DefaultRole.json")
}

resource "aws_iam_role_policy" "emr_profile_policy" {
  name        = "${var.namespace}-${var.project}-${var.stage}-iam-emr-profile-policy"

  role   = aws_iam_role.emr_ec2_role.id
  policy = file("./permissions/EmrEc2DefaultPolicy.json")
}

resource "aws_iam_instance_profile" "emr_ec2_profile" {
  name = "${var.namespace}-${var.project}-${var.stage}-emr-ec2-profile"
  role = aws_iam_role.emr_ec2_role.name
}