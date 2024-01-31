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

data "external" "git_ip_address" {
  program = ["sh", "${path.module}/script.sh"]
  query = {
    git_domain_name = "${var.git_domain_name}"
  }
}

resource "google_compute_address" "address" {
  project      = var.project_id
  region       = var.region
  name         = "${var.prefix}-address"
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
# todo can we split backends based on git url ?
# todo check fqdn

# Problem: terraform supports only SERVERLESS and PRIVATE_SERVICE_CONNECT network_endpoint_types for region_network_endpoint_group
# but INTERNET_IP_PORT is needed. 
# can be done via gcloud:
#TODO try global
#https://github.com/hashicorp/terraform-provider-google/issues/17000
# resource "google_compute_region_network_endpoint_group" "network_endpoint_group" {
#   project    = var.project_id
#   name                  = "${var.prefix}-network-endpoint-group"
#   network_endpoint_type = "INTERNET_IP_PORT"
#   default_port          = "443"
#   region = var.region
# }

resource "null_resource" "region_network_endpoint_group" {
  #Local exec with gcloud due to the missing network_endpoint_type in google_compute_region_network_endpoint_group

  triggers = {
    prefix     = var.prefix
    region     = var.region
    network    = var.network
    project_id = var.project_id
  }

  provisioner "local-exec" {
    command = <<EOD
gcloud compute network-endpoint-groups create ${self.triggers.prefix}-network-endpoint-group \
--default-port=443 \
--network-endpoint-type=internet-ip-port \
--region=${self.triggers.region} \
--network=${self.triggers.network} \
--project=${self.triggers.project_id} \
EOD
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<EOD
gcloud compute network-endpoint-groups delete ${self.triggers.prefix}-network-endpoint-group \
--region=${self.triggers.region} \
--project=${self.triggers.project_id}
EOD
  }
}

data "google_compute_region_network_endpoint_group" "region_network_endpoint_group" {
  project    = var.project_id
  name       = "${var.prefix}-network-endpoint-group"
  region     = var.region
  depends_on = [null_resource.region_network_endpoint_group]
}

# resource "google_compute_global_network_endpoint" "network_endpoint" {
#   project    = var.project_id
#    #todo
#   global_network_endpoint_group = data.google_compute_region_network_endpoint_group.region_network_endpoint_group.id
#   ip_address                    = data.external.git_ip_address.result.git_ip_address
#    #todo
#   port                          = "443" #data.google_compute_region_network_endpoint_group.region_network_endpoint_group.default_port
# }

resource "null_resource" "network_endpoint" {
  #Local exec with gcloud due to the regional endpoint type not supporting ip in terraform
  triggers = {
    region_network_endpoint_group_id = data.google_compute_region_network_endpoint_group.region_network_endpoint_group.id
    git_ip_address                   = data.external.git_ip_address.result.git_ip_address
    region                           = var.region
    project_id                       = var.project_id
  }

  provisioner "local-exec" {
    command = <<EOD
gcloud compute network-endpoint-groups update ${self.triggers.region_network_endpoint_group_id} \
--add-endpoint=ip=${self.triggers.git_ip_address},port=443 \
--region=${self.triggers.region} \
--project=${self.triggers.project_id}
EOD
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<EOD
gcloud compute network-endpoint-groups update ${self.triggers.region_network_endpoint_group_id} \
--remove-endpoint=ip=${self.triggers.git_ip_address},port=443 \
--region=${self.triggers.region} \
--project=${self.triggers.project_id}
EOD
  }

  depends_on = [null_resource.region_network_endpoint_group]
}

resource "google_compute_region_backend_service" "backend_service" {
  project               = var.project_id
  name                  = "${var.prefix}-git-backend-service"
  region                = var.region
  protocol              = "TCP"
  port_name             = "tcp"
  load_balancing_scheme = "INTERNAL_MANAGED"
  timeout_sec           = 10
  health_checks         = [google_compute_region_health_check.tcp_region_health_check.id]
  backend {
    #todo change data to resource 
    group           = data.google_compute_region_network_endpoint_group.region_network_endpoint_group.id
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }
  log_config {
    enable      = true
    sample_rate = 1.0
  }
}

resource "google_compute_region_target_tcp_proxy" "target_tcp_proxy" {
  project         = var.project_id
  region          = var.region
  name            = "${var.prefix}-git-target-tcp-proxy"
  backend_service = google_compute_region_backend_service.backend_service.id
}

resource "google_compute_forwarding_rule" "forwarding_rule" {
  project               = var.project_id
  name                  = "${var.prefix}-git-forwarding-rule"
  region                = var.region
  ip_protocol           = "TCP"
  load_balancing_scheme = "INTERNAL_MANAGED"
  port_range            = "443"
  target                = google_compute_region_target_tcp_proxy.target_tcp_proxy.id
  ip_address            = google_compute_address.address.address

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

#The nat endpoint-types must be ENDPOINT_TYPE_MANAGED_PROXY_LB
#Don't use ENDPOINT_TYPE_VM while for this scenario the type MANAGED_PROXY_LB is necessary 
#(otherwise the health checks originated by the proxy network load balancer will never be NATed with a public source IP 
#and will never reach the target of the regional internet NEG). 
#Currently (5.11.0) the endpoint-types field is not available in terraform provider.

#https://github.com/hashicorp/terraform-provider-google/issues/17001

# resource "google_compute_router_nat" "nat_lb" {
#   project                            = var.project_id
#   name                               = "${var.prefix}-lb-router-nat"
#   router                             = google_compute_router.router.name
#   region                             = google_compute_router.router.region
#   nat_ip_allocate_option             = "AUTO_ONLY"
#   source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

#   endpoint-types = ENDPOINT_TYPE_VM

#   log_config {
#     enable = true
#     filter = "ERRORS_ONLY"
#   }
# }

resource "null_resource" "nat_lb" {
  #Local exec with gcloud due to the missing endpoint-types in google_compute_router_nat
  triggers = {
    compute_router_name   = google_compute_router.router.name
    compute_router_region = google_compute_router.router.region
    project_id            = var.project_id
    prefix                = var.prefix
  }

  provisioner "local-exec" {
    command = <<EOD
gcloud compute routers nats create ${self.triggers.prefix}-lb-router-nat \
--router=${self.triggers.compute_router_name} \
--endpoint-types=ENDPOINT_TYPE_MANAGED_PROXY_LB \
--region=${self.triggers.compute_router_region} \
--project=${self.triggers.project_id} \
--auto-allocate-nat-external-ips \
--nat-all-subnet-ip-ranges \
--enable-logging \
--log-filter=ERRORS_ONLY
EOD
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<EOD
gcloud compute routers nats delete ${self.triggers.prefix}-lb-router-nat \
--region=${self.triggers.compute_router_region} \
--project=${self.triggers.project_id}
EOD
  }
  depends_on = [google_compute_router.router]
}

#this one is created for the vms
resource "google_compute_router_nat" "nat_vm" {
  project                            = var.project_id
  name                               = "${var.prefix}-vm-router-nat"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  #endpoint-types = ENDPOINT_TYPE_VM

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

