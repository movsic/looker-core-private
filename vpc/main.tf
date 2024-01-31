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

locals {
  firewall_rules = {
    "ssh" : 22,
    "rdp" : 3389,
    "http" : 80,
    "https" : 443
  }
}

resource "google_compute_network" "compute_network" {
  project                 = var.project_id
  name                    = var.network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "compute_subnetwork" {
  project                  = var.project_id
  name                     = var.subnet_name
  ip_cidr_range            = var.subnet_address_range
  region                   = var.subnet_region
  network                  = google_compute_network.compute_network.id
  private_ip_google_access = true #needed for the looker proxy vm to access the gcr
}

resource "google_service_networking_connection" "psa_connection" {
  network                 = google_compute_network.compute_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.psa_peering_range.name]
}

resource "google_compute_global_address" "psa_peering_range" {
  project       = var.project_id
  name          = "psa-peering-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  address       = split("/", var.psa_subnet_address_range)[0]
  prefix_length = split("/", var.psa_subnet_address_range)[1]
  network       = google_compute_network.compute_network.id
}

resource "google_compute_firewall" "compute_firewall" {
  for_each = local.firewall_rules
  project  = var.project_id
  name     = "allow-${each.key}"
  network  = google_compute_network.compute_network.id

  allow {
    protocol = "tcp"
    ports    = [each.value]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = [each.key]
}

# resource "google_compute_subnetwork" "proxy_subnetwork" {
#   project = var.project_id
#   name    = "proxy-subnetwork"
#   region  = var.subnet_region
#   network       = google_compute_network.compute_network.id
#   ip_cidr_range = var.proxy_subnet_address_range
#   purpose       = "REGIONAL_MANAGED_PROXY"
#   role          = "ACTIVE"
# }

resource "google_compute_subnetwork" "ilb_subnetwork" {
  project       = var.project_id
  name          = "ilb-subnetwork"
  region        = var.subnet_region
  network       = google_compute_network.compute_network.id
  ip_cidr_range = var.ilb_subnet_address_range
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
}

resource "google_compute_subnetwork" "psc_subnetwork" {
  project       = var.project_id
  name          = "psc-subnetwork"
  region        = var.subnet_region
  network       = google_compute_network.compute_network.id
  purpose       = "PRIVATE_SERVICE_CONNECT"
  ip_cidr_range = var.psc_subnet_address_range
}

resource "google_compute_firewall" "health_checks_firewall" {
  project       = var.project_id
  name          = "allow-health-checks"
  direction     = "INGRESS"
  network       = google_compute_network.compute_network.id
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  allow {
    protocol = "tcp"
  }
  target_tags = ["allow-health-check"]
}