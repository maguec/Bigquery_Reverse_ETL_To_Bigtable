variable "gcp_project_id" {
  type        = string
  description = "The GCP project ID to apply this config to."
}

variable "gcp_zone" {
  type        = string
  description = "The GCP zone to apply this config to."
}

variable "location" {
  type        = string
  description = "The BQ location defaults to the US"
  default     = "US"
}

variable "disable_apis" {
  type        = bool
  description = "Do we disable apis when we are done"
  default     = false
}

variable "suffix" {
  type    = string
  default = ""
}

variable "enable_external" {
  type    = bool
  default = true
}

variable "machine_type" {
  type    = string
  default = "n1-standard-4"
}

variable "instance_family" {
  type    = string
  default = "ubuntu-2204-lts"
}

variable "instance_project_id" {
  type    = string
  default = "ubuntu-os-cloud"
}
