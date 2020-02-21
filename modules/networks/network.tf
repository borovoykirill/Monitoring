# Create VPC with name kbaravoy-vpc
resource "google_compute_network" "kbaravoy-vpc" {
  name                    = "${var.network_name}"
  description             = "VPC network"
  auto_create_subnetworks = false
}

output "network_name" {
  value = "${google_compute_network.kbaravoy-vpc.name}"
}
