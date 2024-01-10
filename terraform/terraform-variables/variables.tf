variable "region" {
  description = "The AWS region"
  default     = "eu-west-1"
}

variable "vpc_name" {
  description = "The name of the VPC"
  default     = "eks-vpc"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "List of availability zones"
  default     = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets"
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets"
  default     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  default     = true
}

variable "eks_cluster_name" {
  description = "The name of the EKS cluster"
  default     = "eks-cluster"
}

variable "eks_cluster_version" {
  description = "The version of the EKS cluster"
  default     = "1.28"
}

variable "eks_node_group_name" {
  description = "The name of the EKS node group"
  default     = "default"
}

variable "eks_node_instance_type" {
  description = "The instance type for EKS managed nodes"
  default     = "t2.small"
}

variable "eks_min_nodes" {
  description = "Minimum number of nodes for the EKS node group"
  default     = 1
}

variable "eks_max_nodes" {
  description = "Maximum number of nodes for the EKS node group"
  default     = 1
}

variable "fargate_profile_name" {
  description = "The name of the EKS Fargate profile"
  default     = "default-profile"
}

variable "vpc_tags" {
  description = "Tags for the VPC"
  type        = map(string)
  default     = {
    Environment = "dev"
    Terraform   = "true"
  }
}

variable "eks_tags" {
  description = "Tags for the EKS resources"
  type        = map(string)
  default     = {
    Environment = "dev"
    Terraform   = "true"
  }
}

