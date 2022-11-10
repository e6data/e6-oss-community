resource "google_dataproc_cluster" "cluster" {
  name     = "${var.cluster_name}-${var.uuid}"
  region   = var.region
  graceful_decommission_timeout = "120s"
  labels = {
    cluster = "presto"
    app     = "e6data"
    cluster_name= var.cluster_name
  }


  cluster_config {

    master_config {
      num_instances = 1
      machine_type  = var.instance_count == 1 ? "c2-standard-30" : "c2-standard-8"
      disk_config {
        boot_disk_type    = "pd-ssd"
        boot_disk_size_gb = "100"
      }
    }

    worker_config {
      num_instances    = var.instance_count == 1 ? 0 : (var.instance_count > 2 && var.enable_spot == true? 2: var.instance_count)
      machine_type     = "c2-standard-30"
      disk_config {
        boot_disk_size_gb = 500
        num_local_ssds    = 4
      }
    }

    preemptible_worker_config {
      num_instances = var.instance_count > 2 && var.enable_spot == true ? var.instance_count - 2 : 0
    }

    # Override or set some custom properties
    software_config {
      image_version = "2.0.35-debian10"
      optional_components = ["PRESTO"]
      override_properties = {
        "dataproc:dataproc.allow.zero.workers" = "true"
        "presto-catalog:hive.connector.name" = "hive-hadoop2"
        "presto-catalog:hive.hive.metastore.uri" = "thrift://${var.hive_host}:9083"
        "presto:query.max-history": "200"
        "presto:enable-dynamic-filtering": "TRUE"
        "presto:join-distribution-type": "AUTOMATIC"
        "presto:optimizer.dictionary-aggregation": "TRUE"
        "presto:optimizer.join-reordering-strategy": "AUTOMATIC"
        "presto:spill-compression-enabled": "TRUE"

      }
    }

    gce_cluster_config {
      subnetwork = var.subnetwork
      tags = [var.cluster_name]
      service_account_scopes = [
        "storage-ro"
      ]
    }
  }
}

resource "google_compute_firewall" "presto-dataproc" {
  name    = "${var.cluster_name}-${var.uuid}"
  network = var.network
  source_tags = [var.cluster_name]
  source_ranges = ["0.0.0.0/0"]
  target_tags = [var.cluster_name]
  allow {
    protocol = "TCP"
    ports = ["8060"]
  }
}

resource "google_compute_firewall" "presto-dataproc-internal" {
  name    = "${var.cluster_name}-${var.uuid}-internal"
  network = var.network
  source_tags = [var.cluster_name]
  source_ranges = [data.google_compute_subnetwork.subnetwork_cidr.ip_cidr_range]
  target_tags = [var.cluster_name]
  priority = 65534
  allow {
    protocol = "TCP"
    ports = ["0-65535"]
  }
  allow {
    protocol = "UDP"
    ports = ["0-65535"]
  }
  allow {
    protocol = "icmp"
  }
}


data "google_compute_instance" "master_info" {
  name = google_dataproc_cluster.cluster.cluster_config[0].master_config[0].instance_names[0]
  zone = google_dataproc_cluster.cluster.cluster_config[0].gce_cluster_config[0].zone
  depends_on = [google_dataproc_cluster.cluster]
}

