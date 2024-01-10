locals {
  name = "value"
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

  cluster_name    = "eks-cluster"
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

# EKS Fargate Profile in kube-system namespace in private subnets
resource "aws_eks_fargate_profile" "kube_system" {
  cluster_name           = module.eks.cluster_id
  fargate_profile_name   = "kube-system"
  pod_execution_role_arn = module.eks.fargate_instance_roles["kube-system"].arn

  # These subnets must have the following resource tag:
  # kubernetes.io/cluster/<CLUSTER_NAME>.
  subnet_ids = module.vpc.private_subnets

  selector {
    namespace = "kube-system"
  }
}

resource "null_resource" "patch_coredns" {
  depends_on = [aws_eks_fargate_profile.kube_system]

  triggers = {
    cluster_name = module.eks.cluster_name
  }

  provisioner "local-exec" {
    command = <<-EOF
      kubectl get deployment coredns -n kube-system -o json | \
      jq 'del(.spec.template.metadata.annotations."eks.amazonaws.com~1compute-type")' | \
      kubectl apply -f -
    EOF
  }
}

