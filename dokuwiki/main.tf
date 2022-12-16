
variable "credentials_file" { 
  default = "/home/don5496/cloud-1-362706-f099cb507aba.json" 
}

variable "project" {
  default = "cloud-1-362706"
}

variable "region" {
  default = "us-central1"
}

variable "zone" {
  default = "us-central1-c"
}

variable "instance_type" {
  default = "e2-micro"
}

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.5.0"
    }
  }
}

provider "google" {
  credentials = file(var.credentials_file)
  project = var.project
  region  = var.region
  zone    = var.zone
}

resource "google_compute_network" "vpc_network" {
  name = "cis91-network"
}

resource "google_compute_instance" "vm_instance" {
  name         = "cis91"
  machine_type = var.instance_type
  allow_stopping_for_update = true

  boot_disk {
    source = google_compute_disk.system.self_link
  }

  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {
    }
  }

  attached_disk {
    source = google_compute_disk.data.self_link
    device_name = "data"
  }

  service_account {
    email = google_service_account.wiki-service-account.email
    scopes = ["cloud-platform"]
  }

}

resource "google_service_account" "wiki-service-account" {
  account_id   = "wiki-service-account"
  display_name = "wiki-service-account"
  description = "Service account for docuwiki"
}

resource "google_project_iam_member" "project_member" {
  role = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.wiki-service-account.email}"
}

resource "google_compute_disk" "system" {
  name  = "system"
  type  = "pd-ssd"
  image = "ubuntu-os-cloud/ubuntu-2004-lts"
  labels = {
    environment = "dev"
  }
  size = "100"
}

resource "google_compute_disk" "data" {
  name  = "data"
  type  = "pd-ssd"
  labels = {
    environment = "dev"
  }
  size = "100"
}

resource "google_storage_bucket" "wiki" {
  name          = "wiki-bucket"
  location      = "US"
  storage_class = "STANDARD"
  force_destroy = true
}

resource "google_compute_firewall" "default-firewall" {
  name = "default-firewall"
  network = google_compute_network.vpc_network.name
  allow {
    protocol = "tcp"
    ports = ["22", "80"]
  }
  source_ranges = ["0.0.0.0/0"]
}

output "external-ip" {
  value = google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip
}
