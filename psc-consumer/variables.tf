variable "project_id" {
  type        = string
  description = "Project id, references existing project."
}

variable "network" {
  type        = string
  description = "VPC network name."
}

variable "subnetwork" {
  type        = string
  description = "VPC subnetwork name."
}

variable "region" {
  type        = string
  description = "Region where Proxy instance is hosted."
}

variable "psc_producer" {
  type = string
  description = "The target service url used to set up private service connection."
}