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

resource "google_compute_region_backend_service" "producer_service_backend" {
  project               = var.project_id
  region                = var.region
  name                  = "${var.prefix}-backend-service"
  load_balancing_scheme = "INTERNAL_MANAGED"
  protocol              = "HTTPS"
  port_name             = "https"
  health_checks         = [google_compute_health_check.compute_health_check.id]
  backend {
    group           = google_compute_region_instance_group_manager.mig.instance_group
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }
  log_config {
    enable      = true
    sample_rate = 1.0
  }
}

resource "google_compute_region_url_map" "url_map" {
  project         = var.project_id
  region          = var.region
  name            = "${var.prefix}-url-map"
  default_service = google_compute_region_backend_service.producer_service_backend.id
}

# resource "google_compute_managed_ssl_certificate" "ssl_certificate" {
#   project         = var.project_id
#   name        = "${var.prefix}-certificate"
#   managed {
#     domains = ["${var.looker_domain}."]
#   }
# }

resource "google_compute_region_ssl_certificate" "ssl_certificate" {
  project     = var.project_id
  region      = var.region
  name        = "${var.prefix}-certificate"
  private_key = tls_private_key.private_key.private_key_pem
  certificate = tls_self_signed_cert.cert.cert_pem
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "cert" {
  private_key_pem = tls_private_key.private_key.private_key_pem

  subject {
    common_name = var.looker_domain
  }

  validity_period_hours = 12

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "google_compute_region_target_https_proxy" "target_https_proxy" {
  project          = var.project_id
  region           = var.region
  name             = "${var.prefix}-target-http-proxy"
  url_map          = google_compute_region_url_map.url_map.id
  ssl_certificates = [google_compute_region_ssl_certificate.ssl_certificate.id]
}

resource "google_compute_address" "lb_address" {
  project      = var.project_id
  region       = var.region
  name         = "${var.prefix}-lb-address"
  address_type = "INTERNAL"
  subnetwork   = var.subnetwork
  #   purpose      = "SHARED_LOADBALANCER_VIP"
}

resource "google_compute_forwarding_rule" "compute_forwarding_rule" {
  project = var.project_id
  region  = var.region
  name    = "${var.prefix}-https-forwarding-rule"

  load_balancing_scheme = "INTERNAL_MANAGED"
  port_range            = "443"
  allow_global_access   = true
  target                = google_compute_region_target_https_proxy.target_https_proxy.id
  ip_protocol           = "TCP"
  ip_address            = google_compute_address.lb_address.address

  network    = var.network
  subnetwork = var.subnetwork
}

# https redirect disabled due to the problem with PSC and SHARED_LOADBALANCER_VIP
# Producer load balancers do not support the following features: 
# Multiple forwarding rules that use a shared IP address (SHARED_LOADBALANCER_VIP)
# https://cloud.google.com/vpc/docs/about-vpc-hosted-services#limitations

# resource "google_compute_region_url_map" "http_redirect" {
#   project = var.project_id
#   region = var.region
#   name = "${var.prefix}-http-redirect-url-map"

#   default_url_redirect {
#     redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
#     strip_query            = false
#     https_redirect         = true
#   }
# }

# resource "google_compute_region_target_http_proxy" "http_redirect" {
#   project = var.project_id
#   region = var.region
#   name    = "${var.prefix}-http-redirect-proxy"
#   url_map = google_compute_region_url_map.http_redirect.self_link
# }

# resource "google_compute_forwarding_rule" "http_redirect" {
#   project = var.project_id
#   region = var.region
#   load_balancing_scheme = "INTERNAL_MANAGED"
#   allow_global_access   = true
#   name       = "${var.prefix}-http-redirect-rule"
#   target     = google_compute_region_target_http_proxy.http_redirect.id
#   ip_protocol           = "TCP"
#   ip_address = google_compute_address.lb_address.address
#   port_range = "80"

#   network    = var.network
#   subnetwork = var.subnetwork
# }