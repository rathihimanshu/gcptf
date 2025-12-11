provider "google" {
  project = var.project_id
  region  = var.region
}

# Simple GKE cluster + default node pool disabled
resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = "us-central1-a"

  # Use existing VPC/subnet (default)
  network    = var.network
  subnetwork = var.subnetwork

  # We create node pool separately
  remove_default_node_pool = true
  initial_node_count       = 1

  # Basic networking mode
  networking_mode = "VPC_NATIVE"

  ip_allocation_policy {} # use default ranges

  # Basic logging/monitoring (for demo)
  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  release_channel {
    channel = "REGULAR"
  }

  # Optional: basic cluster config
  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }
}

# Separate managed node pool
resource "google_container_node_pool" "primary_nodes" {
  name       = "${var.cluster_name}-node-pool"
  location   = "us-central1-a"
  cluster    = google_container_cluster.primary.name
  node_count = 1

  node_config {
    machine_type = "e2-medium"

    disk_size_gb = 50              # reduce disk size (default is 100)
    disk_type    = "pd-standard"        # this is what consumes SSD_TOTAL_GB quota

    # Service account for nodes (uses default if not specified)
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_only",
    ]

    # Optional metadata
    labels = {
      env = "dev"
    }

    tags = ["gke-node", "demo"]
  }

  management {
    auto_upgrade = true
    auto_repair  = true
  }

  autoscaling {
    min_node_count = 1
    max_node_count = 2
  }
}

output "cluster_name" {
  value = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  value = google_container_cluster.primary.endpoint
}

output "cluster_location" {
  value = google_container_cluster.primary.location
}

