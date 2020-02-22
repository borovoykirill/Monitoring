# Create FW rules - accept external SSH connection to client-host via tags=client
resource "google_compute_firewall" "external" {
  name    = "external"
  network = "${google_compute_network.kbaravoy-vpc.self_link}"

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "389", "387"]
  }

  target_tags = ["client", "server"]
}

# Output for main.tf
output "google_compute_firewall_rules" {
  value = "${google_compute_firewall.external.self_link}"
}
