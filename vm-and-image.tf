# Debian 11 base image
data "google_compute_image" "debian11" {
  family  = "debian-11"
  project = "debian-cloud"
}

# Dedicated disk that will become our base for the custom image
resource "google_compute_disk" "base_disk" {
  name  = "debian11-base-disk"
  type  = "pd-balanced"
  zone  = "us-central1-a"
  size  = 10

  # Initialize from Debian 11 image
  image = data.google_compute_image.debian11.self_link
}
resource "google_compute_instance" "base_vm" {
  name         = "debian11-base-vm"
  machine_type = "e2-micro"
  zone         = "us-central1-a"

  tags = ["allow-app-port"]

  # Boot from the existing disk
  boot_disk {
    source = google_compute_disk.base_disk.id
  }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata_startup_script = file("${path.module}/startup.sh")

  # Optional
  lifecycle {
    create_before_destroy = true
  }
}
resource "google_compute_snapshot" "base_snapshot" {
  name        = "debian11-base-snap"
  source_disk = google_compute_disk.base_disk.id

  # Make sure the VM at least exists and has booted once
  depends_on = [
    google_compute_instance.base_vm
  ]
}
resource "google_compute_image" "custom_image" {
  name   = "debian11-custom-image"
  family = "debian11-custom-family"

  source_snapshot = google_compute_snapshot.base_snapshot.self_link

  description = "Custom image created from debian11-base-vm with nginx/app pre-installed."
}
