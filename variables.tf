variable "project_id" {
  type        = string
  description = ""
}

variable "looker_name" {
  type        = string
  description = ""
}

variable "region" {
  type        = string
  description = ""
}

variable "zone" {
  type        = string
  description = ""
}

variable "looker_edition" {
  type        = string
  description = ""
}

variable "looker_domain" {
  type        = string
  description = ""
}

variable "oauth_client_id" {
  type        = string
  description = ""
}

variable "oauth_client_secret" {
  type        = string
  description = ""
}

variable "external_resources" {
  type        = list(string)
  description = "List of external services or resources outside of the instance's VPC network needed to be accessed by Looker Cloud Core"
}

# psc_consumer_project_id
# var.psc_consumer_network
# var.psc_consumer_subnetwork
# var.psc_consumer_region