# Create FW rules - accept all
resource "google_compute_firewall" "all" {
  name    = "all"
  network = "${google_compute_network.kbaravoy-vpc.self_link}"

  allow {
    protocol = "all"
  }

  target_tags = ["vm"]
}

# Output for main.tf
output "google_compute_firewall_rules" {
  value = "${google_compute_firewall.all.self_link}"
}
