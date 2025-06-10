variable "resource_group_location" {
  default     = "canadacentral"
  description = "Location of the resource group."
}

variable "prefix" {
  type        = string
  default     = "t-webapp"
  description = "Test Azure web app"
}
