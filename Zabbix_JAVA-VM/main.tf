provider "google" {
  credentials = "${file("dev-001-project-a8b4975949ab.json")}"
  project     = "dev-001-project"
  region      = "us-central1"
}

# Mount instances module (create server and clients LDAP hosts)
module "instances" {
  source                        = "./modules/instances"
  network_name                  = "${module.networks.network_name}"
  subnet-1-name                 = "${module.networks.subnet-1-name}"
  google_compute_firewall_rules = "${module.networks.google_compute_firewall_rules}"
}

# Mount networks module (create firewall rules; VPC networks and subnetworks)
module "networks" {
  source = "./modules/networks"
}
