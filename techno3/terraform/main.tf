locals {
  name = value
}
provider "aws" {
  region = "ap-south-1"
}

# Create a new VPC
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 2.0"

  name               = "eks-vpc"
  cidr               = "10.0.0.0/16"
  azs                = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
  private_subnets    = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  enable_nat_gateway = true

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

# Create an EKS cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = "eks-clusters"
  cluster_version = "1.28"

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.public_subnets

  cluster_endpoint_public_access = true

  # Node Group with a single node t2.medium
  eks_managed_node_groups = {
    default = {
      desired_size      = 1
      max_size          = 1
      min_size          = 1
      instance_types    = ["t2.medium"]
      capacity_type     = "ON_DEMAND"
    }
  }

  # Fargate Profile in kube-system namespace in private subnets
  fargate_profiles = {
    kube_system = {
      name      = "kube-system"
      selectors = [{ namespace = "kube-system" }]
      subnets   = module.vpc.private_subnets
    }
  }


  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

# Null resource for kubectl patch command
resource "null_resource" "kubectl_patch" {
  provisioner "local-exec" {
    command = <<-EOT
      kubectl patch deployment coredns -n kube-system --type json -p='[{"op": "remove", "path": "/spec/template/metadata/annotations/eks.amazonaws.com~1compute-type"}]'
    EOT
  }

  depends_on = [module.eks]
}
