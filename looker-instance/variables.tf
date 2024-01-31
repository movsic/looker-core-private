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

variable "network" {
  type        = string
  description = "VPC network name, references existing network."
}

variable "name" {
  type        = string
  description = "Looker instance name."
}

variable "region" {
  type        = string
  description = "Region where looker instance is hosted."
}

variable "edition" {
  type        = string
  description = "Looker edition. Can be: LOOKER_CORE_TRIAL,LOOKER_CORE_STANDARD,LOOKER_CORE_STANDARD_ANNUAL,LOOKER_CORE_ENTERPRISE_ANNUAL,LOOKER_CORE_EMBED_ANNUAL."
}

variable "oauth_client_id" {
  type = string
  # todo
  description = "OAuth app client id that will allow users to authenticate and access the instance"
}

variable "oauth_client_secret" {
  type = string
  # todo
  description = "OAuth app secret that will allow users to authenticate and access the instance"
}

variable "looker_domain" {
  type        = string
  description = "Custom domain of the looker instance."
}

variable "config" {
  type = map(string)
  default = {
    private_ip_enabled = true
    public_ip_enabled  = false
    # allowed_email_domains = "google.com"
  }
  description = "Additional looker configuration."
}