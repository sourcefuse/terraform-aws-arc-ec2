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

variable "alb_name" {
  description = "Name of the Application Load Balancer (ALB)."
  type        = string
}

variable "target_group_name" {
  description = "Name of the target group for ALB."
  type        = string
}

variable "listener_port" {
  description = "Port for the ALB listener."
  type        = number
  default     = 80
}

variable "domain_name" {
  description = "Name of the Application Load Balancer (ALB)."
  type        = string
  default     = "shekar.world"
}
