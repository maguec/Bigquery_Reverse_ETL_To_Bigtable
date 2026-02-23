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
