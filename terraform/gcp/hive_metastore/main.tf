resource "google_compute_firewall" "metastore_firewall" {
  name          = "hive-metastore-firewall"
  network       = data.google_compute_network.e6_network.self_link
  source_tags   = ["metastore"]
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["metastore"]
  allow {
    protocol = "TCP"
    ports    = [var.metastore_port]
  }
}

data "google_compute_image" "my_image" {
  family  = "centos-7"
  project = "centos-cloud"
}

resource "google_compute_instance" "metastore" {
  provider = google-beta

  name         = "hive-metastore"
  zone         = data.google_compute_zones.zones.names[0]
  machine_type = var.instance_type
  tags         = ["metastore"]
  network_interface {
    subnetwork = var.subnetwork
    access_config {}
  }

  boot_disk {
    auto_delete = true
    initialize_params {
      image = data.google_compute_image.my_image.self_link
      size  = "100"
      type  = "pd-standard"
    }
  }

  service_account {
    scopes = ["storage-ro"]
  }

  lifecycle {
    create_before_destroy = true
  }
}
