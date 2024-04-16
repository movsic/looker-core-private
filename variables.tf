variable "project_id" {
  type        = string
  description = "Project id, references existing project."
}

variable "looker_name" {
  type        = string
  description = "Looker instance name."
}

variable "region" {
  type        = string
  description = "For regional resources: region where resources are deployed."
}

variable "zone" {
  type        = string
  description = "For zonal resources: zone where resources are deployed."
}

variable "looker_edition" {
  type        = string
  description = "Looker edition. Can be: LOOKER_CORE_TRIAL,LOOKER_CORE_STANDARD,LOOKER_CORE_STANDARD_ANNUAL,LOOKER_CORE_ENTERPRISE_ANNUAL,LOOKER_CORE_EMBED_ANNUAL."
}

variable "looker_domain" {
  type        = string
  description = "Custom domain of the looker instance."
}

variable "oauth_client_id" {
  type        = string
  description = "OAuth app client id that will allow users to authenticate and access the instance."
}

variable "oauth_client_secret" {
  type        = string
  description = "OAuth app secret that will allow users to authenticate and access the instance."
}

variable "external_resources" {
  type        = list(string)
  description = "List of external services or resources outside of the instance's VPC network that Looker Cloud Core needs to access."
}

# psc_consumer_project_id
# var.psc_consumer_network
# var.psc_consumer_subnetwork
# var.psc_consumer_region