/**
 * Copyright 2023 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

variable "project_id" {
  type        = string
  description = "Project id, references existing project."
}

variable "prefix" {
  type        = string
  description = "App name. Will be used as name prefix for all created resources."
  default     = "looker-proxy"
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

variable "looker_ip" {
  type        = string
  description = "Internal IP address of the looker core instance."
}

variable "looker_domain" {
  type        = string
  description = "Custom domain of the looker instance."
}

variable "git_domain_name" {
  type = string
}