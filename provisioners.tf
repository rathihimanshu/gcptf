
provider "google" {
  project = var.project_id
  region  = var.region
  zone = var.zone
}


/* optional: separate provider for EU region (for provider meta-arg demo later) */
provider "google" {
  alias   = "europe"
  project = var.project_id
  region  = "europe-west1"
}

resource "google_compute_network" "demo" {
  name                    = "demo-prov-meta-net"
  auto_create_subnetworks = true
}

resource "google_compute_firewall" "allow_ssh_http" {
  name    = "allow-ssh-http"
  network = google_compute_network.demo.self_link

  allow {
    protocol = "tcp"
    ports    = ["22", "80"]
  }

  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]

  target_tags = ["demo-provisioner"]
}




resource "google_compute_instance" "demo_vm" {
  name         = "demo-provisioners-vm"
  machine_type = "e2-micro"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
  tags = ["demo-provisioner"]

  network_interface {
    network = google_compute_network.demo.self_link
    access_config {} # allocates external IP
  }

  # Inject SSH key (replace 'tfuser' and key path as per your environment)
  metadata = {
    ssh-keys = "tfuser:${file("~/.ssh/id_rsa.pub")}"
  }

  # --- File provisioner: copy startup script to VM ---
  provisioner "file" {
    source      = "startup.sh"
    destination = "/tmp/startup.sh"

    connection {
      type        = "ssh"
      host        = self.network_interface[0].access_config[0].nat_ip
      user        = "tfuser"
      private_key = file("~/.ssh/id_rsa")
    }
  }

  # --- Remote-exec provisioner: run the script on VM ---
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/startup.sh",
      "sudo /tmp/startup.sh"
    ]

    connection {
      type        = "ssh"
      host        = self.network_interface[0].access_config[0].nat_ip
      user        = "tfuser"
      private_key = file("~/.ssh/id_rsa")
    }
  }
}

output "IP" {
  value = google_compute_instance.demo_vm.network_interface[0].access_config[0].nat_ip
  
}

