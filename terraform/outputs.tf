// Outputs EMR cluster dns
output "emr_cluster_dns" {
  value = aws_emr_cluster.emr_cluster.master_public_dns
}

// Saves EMR cluster dns
resource "local_file" "emr_cluster_dns" {
  depends_on = [aws_emr_cluster.emr_cluster]
  filename   = "../emr.cfg"

  content = <<EOT
[EMR]
DNS="${aws_emr_cluster.emr_cluster.master_public_dns}"
KEYPAIR="$HOME/.ssh/${var.ec2_key_pair}.pem"
CLUSTER_ID="${aws_emr_cluster.emr_cluster.id}"
[AWS]
AWS_REGION=""
AWS_ACCESS_KEY_ID=""
AWS_SECRET_ACCESS_KEY=""
EOT
}