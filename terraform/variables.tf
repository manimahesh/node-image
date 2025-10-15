variable "aws_region" {
  description = "The AWS region to deploy resources into."
  type        = string
  default     = "us-west-2"
}

variable "ecr_repository" {
  description = "The name of the ECR repository."
  type        = string
  default     = "mmani-node"
}

variable "eks_cluster_name" {
  description = "The name of the existing EKS cluster to deploy to."
  type        = string
  default     = "ferocious-party-1760228462"
}