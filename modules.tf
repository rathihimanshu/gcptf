provider "google" {
  project = var.project_id
  region  = var.region
  zone = var.zone
}

module "network" {
  source  = "terraform-google-modules/network/google"

  project_id   = var.project_id
  network_name = "demo-vpc"

  subnets = [
    {
      subnet_name   = "demo-subnet-us-central1"
      subnet_ip     = "10.0.0.0/24"
      subnet_region = "us-central1"
      # network = module.network.network_name.name
    }
  ]
}



module "bucket" {
  source  = "terraform-google-modules/cloud-storage/google//modules/simple_bucket"

  project_id    = var.project_id
  name          = "demo-bucket-123456-unique" # must be globally unique
  location      = "US"
  storage_class = "STANDARD"
}

module "vm_template" {
  source  = "terraform-google-modules/vm/google//modules/instance_template"

  project_id  = var.project_id
  region      = "us-central1"
  name_prefix = "demo-vm"

  machine_type         = "e2-medium"
  source_image_family  = "debian-12"
  source_image_project = "debian-cloud"

  network    = module.network.network_name
  subnetwork = "demo-subnet-us-central1"
  subnetwork_project = var.project_id

  tags = ["demo-vm"]
}

module "vm" {
  source  = "terraform-google-modules/vm/google//modules/compute_instance"
  # project_id = var.project_id

  # project_id = var.project_id
  zone       = var.zone

  # name              = "demo-vm-1"
  instance_template = module.vm_template.self_link
}


module "sql_mysql" {
  source  = "GoogleCloudPlatform/sql-db/google//modules/mysql"
  project_id = var.project_id

  # These names/fields are typical; check the module's README for the
  # exact required inputs in your version.
  name               = "demo-mysql"
  database_version   = "MYSQL_8_0"
  tier               = "db-g1-small"    # or db-custom-1-3840 etc.
  deletion_protection = false
}


data "google_client_config" "default" {}

module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google"

  project_id = var.project_id
  name       = "demo-gke"
  region     = "us-central1"
  zones      = ["us-central1-a", "us-central1-b"]

  network    = module.network.network_name
  subnetwork = "demo-subnet-us-central1"

  # for a quick demo you can keep the addon flags simple
  ip_range_pods              = null
  ip_range_services          = null
  http_load_balancing        = true
  network_policy             = false
  horizontal_pod_autoscaling = true
  filestore_csi_driver       = false
  dns_cache                  = false

  node_pools = [
    {
      name           = "default-pool"
      machine_type   = "e2-medium"
      node_locations = "us-central1-a"
      min_count      = 1
      max_count      = 3
      local_ssd_count = 0
      spot           = false
      disk_size_gb   = 50
      disk_type      = "pd-standard"
      image_type     = "COS_CONTAINERD"
      auto_repair    = true
      auto_upgrade   = true
     # service_account = "project-service-account@my-demo-project-id.iam.gserviceaccount.com"
      preemptible    = false
      initial_node_count = 1
    }
  ]

  node_pools_oauth_scopes = {
    all = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}

module "secret_example" {
  source  = "GoogleCloudPlatform/secret-manager/google"
  # Pin to a stable version; 0.5.1 still works well with older google providers
  # version = "0.5.1"

  project_id = var.project_id

  secrets = [
    {
      name        = "demo-secret"
      secret_data = "my-super-secret-password"
      # you can also add rotation fields later if you want
    }
  ]
}



