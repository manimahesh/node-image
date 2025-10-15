# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# --- 1. AWS ECR Repository ---
resource "aws_ecr_repository" "app_repo" {
  name                 = var.ecr_repository
  image_tag_mutability = "MUTABLE" # Allows pushing 'latest' tags multiple times
  
  image_scanning_configuration {
    scan_on_push = true
  }
}

# --- 2. IAM Role for GitHub Actions OIDC Authentication ---

# Data source for the GitHub OIDC provider (required for the trust policy)
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# IAM Role that GitHub Actions will assume
resource "aws_iam_role" "github_oidc_role" {
  name               = "${var.ecr_repository}-github-oidc-role"
  assume_role_policy = data.aws_iam_policy_document.github_trust.json
}

# Trust Policy document for the IAM Role
data "aws_iam_policy_document" "github_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
      type        = "Federated"
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      # IMPORTANT: Replace 'owner/repo' with your actual GitHub repository path
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:manimahesh/node-image:*"]
    }
  }
}

# Policy Document for ECR and EKS access
data "aws_iam_policy_document" "github_actions_policy" {
  statement {
    sid    = "ECRPolicy"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:BatchGetImage",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
    ]
    resources = [
      aws_ecr_repository.app_repo.arn,
      # Allow GetAuthorizationToken on all ECR resources
      "arn:aws:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/*"
    ]
  }

  statement {
    sid    = "EKSReadOnly"
    effect = "Allow"
    actions = [
      "eks:DescribeCluster",
      # Required for aws eks update-kubeconfig
      "eks:ListClusters"
    ]
    resources = ["arn:aws:eks:${var.aws_region}:${data.aws_caller_identity.current.account_id}:cluster/${var.eks_cluster_name}"]
  }
}

# Attach the policy to the IAM Role
resource "aws_iam_role_policy" "github_actions_policy" {
  name   = "github-actions-policy"
  role   = aws_iam_role.github_oidc_role.id
  policy = data.aws_iam_policy_document.github_actions_policy.json
}

# --- 3. EKS Cluster (Data Source) ---
# Retrieve existing EKS Cluster information (assuming EKS is already provisioned)
data "aws_eks_cluster" "cluster" {
  name = var.eks_cluster_name
}

# Get AWS Account ID for resource ARN construction
data "aws_caller_identity" "current" {}

# Output the ARN needed for the GitHub Secret
output "github_actions_role_arn" {
  value       = aws_iam_role.github_oidc_role.arn
  description = "The ARN to be used as a secret in the GitHub Actions workflow (AWS_IAM_ROLE_ARN)"
}