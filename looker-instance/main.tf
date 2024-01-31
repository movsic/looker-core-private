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

data "google_project" "project" {
  project_id = var.project_id
}

data "google_compute_network" "compute_network" {
  project = data.google_project.project.project_id
  name    = element(split("/", var.network), length(split("/", var.network)) - 1)
}

resource "google_looker_instance" "looker_instance" {
  project            = data.google_project.project.project_id
  name               = var.name
  platform_edition   = var.edition
  region             = var.region
  private_ip_enabled = var.config.private_ip_enabled
  public_ip_enabled  = var.config.public_ip_enabled
  # reserved_range     = var.looker_reserved_range_name
  consumer_network = data.google_compute_network.compute_network.id
  #   admin_settings {
  #     allowed_email_domains = var.looker_config.allowed_email_domains
  #   }
  #   encryption_config {
  #     kms_key_name = "looker-kms-key"
  #   }
  #   maintenance_window {
  #     day_of_week = "THURSDAY"
  #     start_time {
  #       hours   = 22
  #       minutes = 0
  #       seconds = 0
  #       nanos   = 0
  #     }
  #   }
  #   deny_maintenance_period {
  #     start_date {
  #       year = 2050
  #       month = 1
  #       day = 1
  #     }
  #     end_date {
  #       year = 2050
  #       month = 2
  #       day = 1
  #     }
  #     time {
  #       hours = 10
  #       minutes = 0
  #       seconds = 0
  #       nanos = 0
  #     }
  #   }
  oauth_config {
    client_id     = var.oauth_client_id
    client_secret = var.oauth_client_secret
  }
}

# resource "google_kms_crypto_key_iam_member" "crypto_key" {
#   crypto_key_id = "looker-kms-key"
#   role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
#   member        = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-looker.iam.gserviceaccount.com"
# }


#Currently adding custom looker domain is not supported by the terraform provider
#null resource with change custom domain
#https://cloud.google.com/sdk/gcloud/reference/looker/instances/update

resource "null_resource" "looker_instance_add_custom_domain" {
  provisioner "local-exec" {
    command = <<EOD
gcloud looker instances update ${var.name} \
--region=${var.region} \
--custom-domain=${var.looker_domain} \
--project=${var.project_id}
EOD
  }
  depends_on = [google_looker_instance.looker_instance]
}