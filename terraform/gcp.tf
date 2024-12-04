provider "google" {
    credentials = file("terraform-service-key.json")
    project     = "devopsstorybooks"
    region      = "us-central1"
    zone        = "us-central1-c"
}

# # Create a Service Account
# resource "google_service_account" "webserver" {
#   account_id   = "webserver-account"
#   display_name = "Web Server Service Account"
# }

# STATIC IP ADDRESS
resource "google_compute_address" "ip_address" {
  name = "storybooks-ip-${terraform.workspace}"
}
# NETWORK
data "google_compute_network" "default" {
  name = "default"
}

# FIREWALL RULL
resource "google_compute_firewall" "allow_http" {
  name    = "allow-http-${terraform.workspace}"
  network = data.google_compute_network.default.name


  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]

  target_tags = [ "allow-http-${terraform.workspace}" ]
}


# OS IMAGE
data "google_compute_image" "ubuntu_image" {
  family  = "ubuntu-2204-lts" 
  project = "ubuntu-os-cloud"
}

# # OS IMAGE
# data "google_compute_image" "cos_image" {
#   family  = "cos-105-lts"
#   project = "cos-cloud"
# }

# COMPUTE ENGINE INSTANCE
resource "google_compute_instance" "instance" {
  name         = "${var.app_name}-vm-${terraform.workspace}"
  machine_type = var.gcp_machine_type
  zone         = "us-central1-a"

  tags = google_compute_firewall.allow_http.target_tags

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu_image.self_link
    }
  }

  network_interface {
    network = data.google_compute_network.default.name

    access_config {
      nat_ip = google_compute_address.ip_address.address
    }
  }
  
  # service_account {
  #   scopes = ["storage-ro"]
  # }

  # service_account {
  #   email  = google_service_account.webserver.email
  #   scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  # }

  service_account {
    email  = "terraform-service@devopsstorybooks.iam.gserviceaccount.com"
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}
