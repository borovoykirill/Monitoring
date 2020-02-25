# Create Tomcat host
resource "google_compute_instance" "host01" {
  name         = "${var.name2}"
  machine_type = "${var.instance_typece}"
  zone         = "us-central1-a"
  tags         = ["vm"]

  metadata_startup_script = "${file("./provision/host01-setup.sh")}"

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
    network_ip    = "10.10.1.10"
    access_config = {}
  }

  labels = {
    servertype        = "tomcat"
    osfamily          = "centos7"
    wayofinstallation = "terraform"
  }
}
