module "vpc" {
  source        = "./vpc"
  project_id    = var.project_id
  subnet_region = var.region
}

module "looker_instance" {
  source              = "./looker-instance"
  project_id          = var.project_id
  name                = var.looker_name
  region              = var.region
  edition             = var.looker_edition
  looker_domain       = var.looker_domain
  oauth_client_id     = var.oauth_client_id
  oauth_client_secret = var.oauth_client_secret
  network             = module.vpc.network_id
}

module "looker_proxy_vm" {
  source          = "./looker-proxy"
  project_id      = var.project_id
  network         = module.vpc.network_id
  subnetwork      = module.vpc.subnet_id
  region          = var.region
  looker_ip       = module.looker_instance.looker_ingress_private_ip
  looker_domain   = var.looker_domain
  git_domain_name = var.git_domain_name
}

# module "looker_psc_producer" {
#   source                 = "./psc-producer"
#   project_id             = var.project_id
#   pcs_nat_subnetwork     = module.vpc.pcs_nat_subnet_id
#   region                 = var.region
#   looker_proxy_lb        = module.looker_proxy_vm.ilb_forwarding_rule_id
# }

module "looker_test_vm" {
  source     = "./test-vms"
  project_id = var.project_id
  network    = module.vpc.network_id
  subnetwork = module.vpc.subnet_id
  zone       = var.zone
}

# module "psc_consumer" {
#   source       = "./psc-consumer"
#   project_id   = var.psc_consumer_project_id
#   network      = var.psc_consumer_network
#   subnetwork   = var.psc_consumer_subnetwork
#   region       = var.psc_consumer_region
#   psc_producer = module.looker_psc.psc_service_attachment
# }