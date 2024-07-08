variable "region" {
  description = "AWS region to deploy resources"
  type        = string
}

variable "namespace" {
  description = "Namespace for naming convention"
  type        = string
}

variable "environment" {
  description = "Environment (e.g., dev, prod)"
  type        = string
}
