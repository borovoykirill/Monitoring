# Create server-LDAP host
resource "google_compute_instance" "server-ldap" {
  name                    = "${var.name}"
  machine_type            = "${var.instance_typece}"
  zone                    = "us-central1-a"
  tags                    = ["server"]
  metadata_startup_script = "${file("./provision/server-setup.sh")}"

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
    servertype        = "serverldap"
    osfamily          = "centos7"
    wayofinstallation = "terraform"
  }
}
