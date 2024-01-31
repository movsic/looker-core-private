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

resource "google_compute_region_network_endpoint_group" "psc_neg" {
  name                  = "psc-neg"
  region                = var.region
  project               = var.project_id
  network_endpoint_type = "PRIVATE_SERVICE_CONNECT"
  psc_target_service    = var.psc_producer

  network    = var.network
  subnetwork = var.subnetwork
}

resource "google_compute_forwarding_rule" "forwarding_rule" {
  project               = var.project_id
  region                = var.region
  name                  = "forwarding-rule"
  load_balancing_scheme = "INTERNAL_MANAGED"
  target                = google_compute_region_target_http_proxy.compute_target_http_proxy.id
  port_range            = "80"
  network               = var.network
  subnetwork            = var.subnetwork
  ip_address            = google_compute_address.lb_address.address
}

resource "google_compute_address" "lb_address" {
  project      = var.project_id
  region       = var.region
  name         = "psc-lb-address"
  address_type = "INTERNAL"
  subnetwork   = var.subnetwork
}

resource "google_compute_region_target_http_proxy" "compute_target_http_proxy" {
  project = var.project_id
  region  = var.region
  name    = "target-proxy"
  url_map = google_compute_region_url_map.compute_url_map.id
}

resource "google_compute_region_url_map" "compute_url_map" {
  project         = var.project_id
  region          = var.region
  name            = "url-map-target-proxy"
  default_service = google_compute_region_backend_service.compute_backend_service.id
}

resource "google_compute_region_backend_service" "compute_backend_service" {
  project               = var.project_id
  region                = var.region
  name                  = "consumer-backend-service"
  load_balancing_scheme = "INTERNAL_MANAGED"
  protocol              = "HTTPS"
  backend {
    group           = google_compute_region_network_endpoint_group.psc_neg.id
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }
}

resource "google_compute_subnetwork" "ilb_subnetwork" {
  project = var.project_id
  name    = "ilb-subnetwork"
  region  = var.region

  network       = var.network
  ip_cidr_range = "10.1.0.0/24"
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
}
