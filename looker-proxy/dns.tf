resource "google_dns_response_policy" "dns_response_policy" {
  project              = var.project_id
  response_policy_name = "looker-response-policy"
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

resource "google_dns_response_policy_rule" "dns_response_policy_rule" {
  for_each        = toset(var.external_resources)
  project         = var.project_id
  response_policy = google_dns_response_policy.dns_response_policy.response_policy_name
  rule_name       = "${replace(each.key, ".", "-")}-rule"
  dns_name        = "${each.key}."

  local_data {
    local_datas {
      name    = "${each.key}."
      type    = "A"
      ttl     = 300
      rrdatas = [google_compute_address.address[each.key].address]
    }
  }
}

resource "google_service_networking_peered_dns_domain" "peered_dns_domain" {
  for_each   = toset(var.external_resources)
  project    = var.project_id
  name       = "${replace(each.key, ".", "-")}-peered-dns-domain"
  network    = element(split("/", var.network), length(split("/", var.network)) - 1)
  dns_suffix = "${each.key}."
  service    = "servicenetworking.googleapis.com" #check?
}