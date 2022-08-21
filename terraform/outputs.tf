// Outputs EMR cluster dns
output "emr_cluster_dns" {
  value = aws_emr_cluster.cluster.master_public_dns
}

// Saves EMR cluster config to emr.cfg
resource "local_file" "emr_cluster_dns" {
  depends_on = [aws_emr_cluster.cluster]
  filename   = "../config/emr.cfg"

  content = <<EOT
[EMR]
DNS=${aws_emr_cluster.cluster.master_public_dns}
KEYPAIR=$HOME/.ssh/${var.ec2_key_pair}.pem
CLUSTER_ID=${aws_emr_cluster.cluster.id}
EOT
}