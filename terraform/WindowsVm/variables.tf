variable "resource_group_location" {
  default     = "eastus"
  description = "Location of the resource group."
}

variable "prefix" {
  type        = string
  default     = "t-ccal-"
  description = "Test Windows VM Cal sub"
}