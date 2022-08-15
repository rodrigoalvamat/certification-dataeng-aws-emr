// Global variables
variable "namespace" {
  description = "Namespace prefix"
  type        = string
  default     = "udacity"
}

variable "stage" {
  description = "Stage prefix"
  type        = string
  default     = "dev"
}

variable "project" {
  description = "Application name prefix"
  type        = string
  default     = "spark"
}

// Common tags
locals {
  common_tags = {
    namespace   = var.namespace
    project = var.project
    stage   = var.stage
  }
}

// AWS region
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "availability_zones" {
  description = "AWS region availability zones"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b", "us-west-2c", "us-west-2d"]
}

// EC2 key pair
variable "ec2_key_pair" {
  description = "EMR Cluster EC2 key pair name"
  type        = string
  default     = "emr-cluster"
}

// VPC subnets
variable "public_subnets" {
  description = "ERM vpc public subnets"
  type        = list(string)
  default     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

variable "private_subnets" {
  description = "ERM vpc private subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

// EMR settings
variable "emr_release" {
  description = "ERM cluster release version"
  type        = string
  default     = "emr-6.7.0"
}

variable "emr_applications" {
  description = "ERM cluster application list"
  type        = list(string)
  default     = ["Spark"]
}

variable "emr_master_instance_type" {
  description = "ERM master EC2 instance type"
  type        = string
  default     = "m4.large"
}

variable "emr_core_instance" {
  description = "ERM worker EC2 instance settings"
  type        = object({ type = string, count = number } )
  default     = {
    type  = "c4.large"
    count = 2
  }
}

variable "emr_roles" {
  description = "ERM cluster roles"
  type        = map(string)
  default     = { service = "arn:aws:iam::977290156131:role/EMR_DefaultRole", instance = "EMR_EC2_DefaultRole" }
}

// S3
variable "s3_bucket" {
  description = "S3 EMR bucket"
  type        = string
  default     = "udacity-dataeng-emr"
}

variable "s3_udacity_bucket" {
  description = "S3 Udacity bucket"
  type        = string
  default     = "udacity-dend"
}

variable "s3_log_uri" {
  description = "S2 EMR log bucket"
  type        = string
  default     = "cluster/logs"
}

variable "s3_data_files" {
  description = "S3 EMR data files"
  type        = map(string)
  default     = {
    source = "../data"
    target = "application/data"
  }
}

variable "s3_app_files" {
  description = "S3 EMR app files"
  type        = object({ source = list(string), target = string } )
  default     = {
    source = [
      "../src/etl/__init__.py",
      "../src/etl/etl.py",
      "../src/etl/etl.cfg",
      "../src/etl/config.py",
      "../src/etl/metadata.py"
    ]
    target = "application/etl"
  }
}

variable "emr_bootstrap" {
  description = "ERM bootstrap action script"
  type        = object({ key = string, name = string, args = list(string), source = string })
  default     = {
    key    = "cluster/bootstrap/bootstrap.sh"
    name   = "spark-bootstrap"
    args   = [],
    source = "../bin/bootstrap.sh"
  }
}