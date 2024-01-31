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
  description = ""
  default     = "looker"
}

variable "region" {
  description = ""
  type        = string
}

variable "looker_proxy_lb" {
  type        = string
  description = "The URL of a forwarding rule that represents the service identified by this service attachment."
}

variable "pcs_nat_subnetwork" {
  type        = string
  description = "A subnet that is provided for NAT in this service attachment."
}