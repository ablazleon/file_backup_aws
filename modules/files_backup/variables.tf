variable "disk-device-name" {
  description = "device name of the volume"
  type        = string
  default     = ""
}

variable "DS-Agent-Public-IP" {
  description = "datasync public ip"
  type        = string
  default     = ""
}

variable "NFSServer-Private-IP" {
  description = "server private ip"
  type        = string
  default     = ""
}
variable "SG-Agent-Public-IP" {
  description = "storage gateway public ip"
  type        = string
  default     = ""
}

