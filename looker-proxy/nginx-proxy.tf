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

resource "null_resource" "docker_build_with_cloud_build" {
  provisioner "local-exec" {
    command = "gcloud builds submit --substitutions=_DOMAIN_NAME=${var.looker_domain},_IP_ADDRESS=${var.looker_ip} --config=looker-proxy/cloudbuild.yaml --project=${var.project_id} ./looker-proxy"
  }
}

locals {
  looker-proxy-sa-roles = [
    "roles/storage.objectUser",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter"
  ]
}

resource "google_compute_instance_template" "looker_proxy_template" {
  project      = var.project_id
  name         = "${var.prefix}-template"
  machine_type = "n2-standard-2"

  disk {
    source_image = "cos-cloud/cos-stable"
    auto_delete  = true
    boot         = true
  }

  # scheduling {
  #   preemptible       = true
  #   automatic_restart = true
  # }

  metadata = {
    gce-container-declaration = "spec:\n  containers:\n    - name: looker-proxy\n      image: 'gcr.io/${var.project_id}/looker-proxy:latest'\n      stdin: false\n      tty: false\n  restartPolicy: Always\n"
  }

  metadata_startup_script = "curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh && sudo bash add-google-cloud-ops-agent-repo.sh --also-install"

  network_interface {
    network    = var.network
    subnetwork = var.subnetwork
  }

  service_account {
    email  = google_service_account.service_account.email
    scopes = ["cloud-platform"]
  }

  tags = ["ssh", "http", "https", "allow-health-check"]
}

resource "google_compute_health_check" "compute_health_check" {
  project             = var.project_id
  name                = "${var.prefix}-health-check"
  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 10

  https_health_check {
    host         = var.looker_domain
    request_path = "/alive"
    port         = "443"
  }

  log_config {
    enable = true
  }
}

resource "google_compute_region_instance_group_manager" "mig" {
  project = var.project_id
  name    = "${var.prefix}-mig"
  region  = var.region
  version {
    instance_template = google_compute_instance_template.looker_proxy_template.id
    name              = "primary"
  }
  base_instance_name = "looker-proxy"
  target_size        = 1

  named_port {
    name = "https"
    port = 443
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.compute_health_check.id
    initial_delay_sec = 300
  }

  depends_on = [null_resource.docker_build_with_cloud_build]
}

resource "google_service_account" "service_account" {
  project    = var.project_id
  account_id = "${var.prefix}-sa"
}

resource "google_project_iam_member" "cloud_run_sa_iam" {
  for_each = toset(concat(local.looker-proxy-sa-roles))
  project  = var.project_id
  role     = each.value
  member = "serviceAccount:${google_service_account.service_account.email}"
}