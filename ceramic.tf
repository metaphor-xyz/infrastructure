module "ceramic-daemon" {
  source  = "terraform-google-modules/container-vm/google"
  version = "2.0.0"

  container = {
    image = "ceramicnetwork/js-ceramic:${var.image_tag}"

    args = [
      "--hostname", "0.0.0.0",
      "--network", "${var.ceramic_network}",
      "--ipfs-api", "http://${google_compute_instance.ipfs-instance.network_interface.0.network_ip}:5001",
      "--state-store-directory", "/data",
    ]

    ports = [
      { "containerPort" : 7007 },
      { "containerPort" : 9229 },
    ]

    volumeMounts = [
      {
        mountPath = "/data"
        name      = "ceramic-data-0"
        readOnly  = false
      }
    ]
  }

  volumes = [
    {
      name = "ceramic-data-0"

      gcePersistentDisk = {
        pdName = "ceramic-data-0"
        fsType = "ext4"
      }
    }
  ]

  restart_policy = "Always"
}


resource "google_compute_disk" "ceramic-disk" {
  project = var.project
  name    = "ceramic-data-0"
  type    = "pd-ssd"
  zone    = var.zone
  size    = 10
}

resource "google_compute_instance" "ceramic-instance" {
  project      = var.project
  name         = "ceramic-daemon"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = module.ceramic-daemon.source_image
    }
  }

  attached_disk {
    source      = google_compute_disk.ceramic-disk.self_link
    device_name = "ceramic-data-0"
    mode        = "READ_WRITE"
  }

  network_interface {
    network            = google_compute_network.vpc_network.id
    subnetwork_project = var.project
    access_config {}
  }

  metadata = { "gce-container-declaration" = module.ceramic-daemon.metadata_value }

  labels = {
    container-vm = module.ceramic-daemon.vm_container_label
  }

  tags = ["ceramic-daemon"]
}

resource "google_compute_firewall" "ceramic-firewall" {
  name    = "ceramic-daemon-http"
  project = var.project
  network = google_compute_network.vpc_network.id

  allow {
    protocol = "tcp"
    ports    = [7007, 9229]
  }

  allow {
    protocol = "tcp"
    ports    = [22]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ceramic-daemon"]
}
