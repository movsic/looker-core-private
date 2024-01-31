resource "google_dns_response_policy" "dns_response_policy" {
  project              = var.project_id
  response_policy_name = "looker-custom-domain"
  networks {
    network_url = var.network
  }
}

resource "google_dns_response_policy_rule" "looker_dns_response_policy_rule" {
  project         = var.project_id
  response_policy = google_dns_response_policy.dns_response_policy.response_policy_name

  rule_name = "looker-custom-domain"
  dns_name  = "${var.looker_domain}."

  local_data {
    local_datas {
      name    = "${var.looker_domain}."
      type    = "A"
      ttl     = 300
      rrdatas = [google_compute_address.lb_address.address]
    }
  }
}

resource "google_dns_response_policy_rule" "git_dns_response_policy_rule" {
  project         = var.project_id
  response_policy = google_dns_response_policy.dns_response_policy.response_policy_name
  rule_name       = "git-repo"
  dns_name        = "${var.git_domain_name}."

  local_data {
    local_datas {
      name    = "${var.git_domain_name}."
      type    = "A"
      ttl     = 300
      rrdatas = [google_compute_address.address.address]
    }
  }
}


# Error waiting for Create Service Networking Peered DNS Domain: Error code 13, message: An internal exception occurred.
resource "google_service_networking_peered_dns_domain" "git_peered_dns_domain" {
  project    = var.project_id
  name       = "${var.prefix}-peered-dns-domain"
  network    = element(split("/", var.network), length(split("/", var.network)) - 1)
  dns_suffix = "${var.git_domain_name}."
  service    = "servicenetworking.googleapis.com" #check?
}