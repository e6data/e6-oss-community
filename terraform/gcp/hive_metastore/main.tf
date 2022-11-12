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
  metadata_startup_script = file("bootstrap_script.sh")
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
