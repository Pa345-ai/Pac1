################################################################################
# AWS Terraform Starter Kit
# Copyright (c) 2025 RUWANPURAGE PAVITHRA PARAMI RANASINGHE
# Licensed for single commercial use - See LICENSE.txt
################################################################################

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project used for resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. production, staging)"
  type        = string
  default     = "production"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "container_image" {
  description = "Docker image URL from ECR"
  type        = string
}

variable "container_port" {
  description = "Port the application listens on"
  type        = number
  default     = 3000
}

variable "cpu" {
  description = "Fargate instance CPU units (256, 512, 1024)"
  type        = number
  default     = 256
}

variable "memory" {
  description = "Fargate instance memory (512, 1024, 2048)"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Number of containers to run"
  type        = number
  default     = 1
}

variable "app_environment_variables" {
  description = "List of public environment variables for the application"
  type = list(object({
    name  = string
    value = string
  }))
  default = [
    {
      name  = "NODE_ENV"
      value = "production"
    }
  ]
}
