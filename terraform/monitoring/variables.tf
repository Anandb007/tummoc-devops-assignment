variable "monitoring_instance_type" {
  description = "EC2 instance type for monitoring"
  default     = "t3.medium"
}

variable "monitoring_instance_count" {
  description = "Number of monitoring instances"
  type        = number
  default     = 0   # Change this to 1,2,... to spin up instances
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
  default     = "tom"  # Optional: leave empty if you don't want prompt
}
