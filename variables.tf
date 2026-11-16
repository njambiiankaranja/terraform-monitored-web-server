variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region to deploy into"
}

variable "availability_zone" {
  type        = string
  default     = "us-east-1a"
  description = "Availability zone for the public subnet"
}

variable "project_name" {
  type        = string
  default     = "monitored-web-server"
  description = "Prefix for resource names and the Project tag"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "CIDR block for the VPC"
}

variable "public_subnet_cidr" {
  type        = string
  default     = "10.0.1.0/24"
  description = "CIDR block for the public subnet"
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"
  description = "EC2 instance type for the web server"
}

variable "cpu_alarm_threshold" {
  type        = number
  default     = 70
  description = "Average CPU percentage that triggers the high CPU alarm"

  validation {
    condition     = var.cpu_alarm_threshold > 0 && var.cpu_alarm_threshold <= 100
    error_message = "cpu_alarm_threshold must be between 1 and 100."
  }
}

variable "alert_email" {
  type        = string
  description = "Email address that receives alarm notifications"

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.alert_email))
    error_message = "alert_email must be a valid email address."
  }
}