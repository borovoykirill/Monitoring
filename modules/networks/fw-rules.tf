# Create FW rules - accept external SSH connection to client-host via tags=client
resource "google_compute_firewall" "ssh-external" {
  name    = "ssh-external"
  network = "${google_compute_network.kbaravoy-vpc.self_link}"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags = ["client", "server"]
}

# Output for main.tf
output "google_compute_firewall_ssh_name" {
  value = "${google_compute_firewall.ssh-external.self_link}"
}
