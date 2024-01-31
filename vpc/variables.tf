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
  description = "Project id, references existing gcp project."
}

variable "network_name" {
  type        = string
  description = "VPC network name. The network will be created."
  default     = "looker-vpc"
}

variable "subnet_name" {
  type        = string
  description = "VPC subnetwork name. The subnetwork will be created."
  default     = "looker-subnet"
}

variable "subnet_region" {
  type        = string
  description = "VPC subnetwork region."
}

variable "subnet_address_range" {
  type        = string
  description = "VPC subnetwork range."
  default     = "10.1.0.0/24"
}

variable "psa_subnet_address_range" {
  type        = string
  description = "IP address range reserved for this service provider. Minimum for psa is 24, recommended is 16."
  default     = "10.0.0.0/20"
}

variable "ilb_subnet_address_range" {
  type        = string
  description = ""
  default     = "10.2.0.0/20"
}

variable "psc_subnet_address_range" {
  type        = string
  description = ""
  default     = "10.3.0.0/20"
}

# variable "proxy_subnet_address_range" {
#   type        = string
#   description = ""
#   default     = "10.4.0.0/20"
# }