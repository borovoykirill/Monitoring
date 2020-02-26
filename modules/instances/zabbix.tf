# Create server host for monitoring
resource "google_compute_instance" "zabbix" {
  name         = "${var.name}"
  machine_type = "${var.instance_typece}"
  zone         = "us-central1-a"
  tags         = ["vm"]

  metadata_startup_script = "${file("./provision/zabbix-setup.sh")}"

  boot_disk {
    initialize_params {
      type  = "pd-ssd"
      size  = "${var.disk_size}"
      image = "${var.image_source}"
    }
  }

  network_interface {
    network       = "${var.network_name}"
    subnetwork    = "${var.subnet-1-name}"
    network_ip    = "10.10.1.11"
    access_config = {}
  }

  labels = {
    servertype        = "zabbixserver"
    osfamily          = "centos7"
    wayofinstallation = "terraform"
  }
}
