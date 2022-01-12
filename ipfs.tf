module "ipfs-daemon" {
  source  = "terraform-google-modules/container-vm/google"
  version = "2.0.0"

  container = {
    image = "ceramicnetwork/ipfs-daemon:${var.image_tag}"

    env = [
      {
        name  = "IPFS_PATH"
        value = "/data"
      }
    ]

    ports = [
      { "containerPort" : 5011 },
      { "containerPort" : 4011 },
    ]

    volumeMounts = [
      {
        mountPath = "/data"
        name      = "ipfs-data-0"
        readOnly  = false
      }
    ]
  }

  volumes = [
    {
      name = "ipfs-data-0"

      gcePersistentDisk = {
        pdName = "ipfs-data-0"
        fsType = "ext4"
      }
    }
  ]

  restart_policy = "Always"
}


resource "google_compute_disk" "ipfs-disk" {
  project = var.project
  name    = "ipfs-data-0"
  type    = "pd-ssd"
  zone    = var.zone
  size    = 10
}

resource "google_compute_instance" "ipfs-instance" {
  project      = var.project
  name         = "ipfs-daemon"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = module.ipfs-daemon.source_image
    }
  }

  attached_disk {
    source      = google_compute_disk.ipfs-disk.self_link
    device_name = "ipfs-data-0"
    mode        = "READ_WRITE"
  }

  network_interface {
    network            = google_compute_network.vpc_network.id
    subnetwork_project = var.project
    access_config {}
  }

  metadata = { "gce-container-declaration" = module.ipfs-daemon.metadata_value }

  labels = {
    container-vm = module.ipfs-daemon.vm_container_label
  }

  tags = ["ipfs-daemon"]
}

resource "google_compute_firewall" "ipfs-firewall" {
  name    = "ipfs-daemon-http"
  project = var.project
  network = google_compute_network.vpc_network.id

  allow {
    protocol = "tcp"
    ports    = [4011, 5011]
  }

  source_tags = ["ceramic-daemon"]
  target_tags = ["ipfs-daemon"]
}

resource "google_compute_firewall" "ipfs-allow-ssh" {
  name    = "ipfs-allow-ssh"
  project = var.project
  network = google_compute_network.vpc_network.id

  allow {
    protocol = "tcp"
    ports    = [22]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ipfs-daemon"]
}
