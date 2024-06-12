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

data "external" "ip_address" {
  for_each = toset(var.external_resources)
  program  = ["sh", "${path.module}/script.sh"]
  query = {
    domain_name = "${each.key}"
  }
}

resource "google_compute_address" "address" {
  for_each     = toset(var.external_resources)
  project      = var.project_id
  region       = var.region
  name         = "${replace(each.key, ".", "-")}-address"
  address_type = "INTERNAL"
  subnetwork   = var.subnetwork
}

resource "google_compute_region_health_check" "tcp_region_health_check" {
  project            = var.project_id
  name               = "${var.prefix}-tcp-health-check"
  region             = var.region
  timeout_sec        = 1
  check_interval_sec = 1

  tcp_health_check {
    port = "80"
  }

  log_config {
    enable = true
  }
}

#Use an Internet NEG of type INTERNET_FQDN_PORT does not work because 
#the DNS configuration done on the VPC where the internal load balancer is created 
#forces the resolution of github.com to the private IP of the load balancer VIP 
#in order to attract the traffic from the Looker Core instance. 
#Below the error log message with an  INTERNET_FQDN_PORT setup.
#proxy_status: destanation_unavailable

resource "google_compute_region_network_endpoint_group" "network_endpoint_group" {
  for_each              = toset(var.external_resources)
  project               = var.project_id
  name                  = "${replace(each.key, ".", "-")}-network-endpoint-group"
  network               = var.network
  network_endpoint_type = "INTERNET_IP_PORT"
  region                = var.region
}

resource "google_compute_region_network_endpoint" "network_endpoint" {
  for_each                      = toset(var.external_resources)
  project                       = var.project_id
  region_network_endpoint_group = google_compute_region_network_endpoint_group.network_endpoint_group[each.key].id
  ip_address                    = data.external.ip_address[each.key].result.ip_address
  port                          = "443"
  region                        = var.region
}

resource "google_compute_region_backend_service" "backend_service" {
  for_each              = toset(var.external_resources)
  project               = var.project_id
  name                  = "${replace(each.key, ".", "-")}-backend-service"
  region                = var.region
  protocol              = "TCP"
  port_name             = "tcp"
  load_balancing_scheme = "INTERNAL_MANAGED"
  timeout_sec           = 10
  health_checks         = [google_compute_region_health_check.tcp_region_health_check.id]
  backend {
    group           = google_compute_region_network_endpoint_group.network_endpoint_group[each.key].id
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }
  log_config {
    enable      = true
    sample_rate = 1.0
  }
}

resource "google_compute_region_target_tcp_proxy" "target_tcp_proxy" {
  for_each        = toset(var.external_resources)
  project         = var.project_id
  region          = var.region
  name            = "${replace(each.key, ".", "-")}-target-tcp-proxy"
  backend_service = google_compute_region_backend_service.backend_service[each.key].id
}

resource "google_compute_forwarding_rule" "forwarding_rule" {
  for_each              = toset(var.external_resources)
  project               = var.project_id
  name                  = "${replace(each.key, ".", "-")}-forwarding-rule"
  region                = var.region
  ip_protocol           = "TCP"
  load_balancing_scheme = "INTERNAL_MANAGED"
  port_range            = "443"
  target                = google_compute_region_target_tcp_proxy.target_tcp_proxy[each.key].id
  ip_address            = google_compute_address.address[each.key].address

  network    = var.network
  subnetwork = var.subnetwork
}

resource "google_compute_router" "router" {
  project = var.project_id
  name    = "${var.prefix}-router"
  region  = var.region
  network = var.network

  bgp {
    asn = 64514 #check
  }
}

resource "google_compute_router_nat" "router_nat" {
  project                            = var.project_id
  name                               = "${var.prefix}-router-nat"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  endpoint_types = ["ENDPOINT_TYPE_VM","ENDPOINT_TYPE_LB"]

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

