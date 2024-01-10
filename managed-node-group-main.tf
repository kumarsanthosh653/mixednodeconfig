locals {
  name = "value"
}

provider "aws" {
  region = var.region
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 2.0"

  name               = var.vpc_name
  cidr               = var.vpc_cidr
  azs                = var.azs
  private_subnets    = var.private_subnet_cidrs
  public_subnets     = var.public_subnet_cidrs
  enable_nat_gateway = var.enable_nat_gateway

  tags = var.vpc_tags
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = var.eks_cluster_name
  cluster_version = var.eks_cluster_version

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.public_subnets

  cluster_endpoint_public_access = true

  eks_managed_node_groups = {
    default = {
      desired_size      = var.eks_min_nodes
      max_size          = var.eks_max_nodes
      min_size          = var.eks_min_nodes
      instance_types    = [var.eks_node_instance_type]
      capacity_type     = "ON_DEMAND"
    }
  }
}

resource "aws_iam_role" "eks_fargate_profile" {
  name = "eks-fargate-profiles"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks-fargate-pods.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "eks_fargate_profile_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.eks_fargate_profile.name
}

resource "aws_eks_fargate_profile" "kube_system" {
  cluster_name           = module.eks.cluster_name
  fargate_profile_name   = var.fargate_profile_name
  pod_execution_role_arn = aws_iam_role.eks_fargate_profile.arn

  subnet_ids = module.vpc.private_subnets

  selector {
    namespace = "kube-system"
  }
}

resource "aws_eks_fargate_profile" "santhosh" {
  cluster_name           = module.eks.cluster_name
  fargate_profile_name   = var.santhosh_fargate_profile_name
  pod_execution_role_arn = aws_iam_role.eks_fargate_profile.arn

  subnet_ids = module.vpc.private_subnets

  selector {
    namespace = "santhosh"
  }
}

resource "aws_iam_role" "eks_node_group" {
  name = "eks-node-group"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_node_group_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group.name
}

resource "aws_eks_node_group" "custom_node_group" {
  cluster_name    = module.eks.cluster_name
  node_group_name = var.custom_node_group_name
  subnet_ids      = module.vpc.private_subnets
  instance_types  = [var.eks_node_instance_type]
  capacity_type   = "ON_DEMAND"
  node_role_arn   = aws_iam_role.eks_node_group.arn

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }
  depends_on = [module.eks]
  
  tags = var.eks_tags
}

resource "null_resource" "patch_coredns" {
  depends_on = [aws_eks_fargate_profile.kube_system]

  triggers = {
    cluster_name = module.eks.cluster_name
  }

  provisioner "local-exec" {
    command = <<-EOF
      aws eks --region ${var.region} update-kubeconfig --name ${var.eks_cluster_name}
      kubectl wait --for=condition=Ready node --all --timeout=5m
      kubectl patch deployment coredns -n kube-system --type json -p='[{"op": "remove", "path": "/spec/template/metadata/annotations/eks.amazonaws.com~1compute-type"}]'
    EOF
  }
}

