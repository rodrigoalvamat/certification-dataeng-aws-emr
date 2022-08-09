// Generates private key
resource "tls_private_key" "emr_private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

// Creates EMR EC2 key pair
resource "aws_key_pair" "emr_key_pair" {
  key_name   = var.ec2_key_pair
  public_key = tls_private_key.emr_private_key.public_key_openssh

  provisioner "local-exec" {
    command = <<EOT
echo "${tls_private_key.emr_private_key.private_key_pem}" > ./${var.ec2_key_pair}.pem
chmod 400 ./${var.ec2_key_pair}.pem
mv ./${var.ec2_key_pair}.pem $HOME/.ssh/
EOT
  }
}