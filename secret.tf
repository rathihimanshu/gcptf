
provider "google" {
  project = var.project_id
  region  = var.region
}

# ---------------------------
# Enable Secret Manager API
# ---------------------------
resource "google_project_service" "secretmanager" {
  project = var.project_id
  service = "secretmanager.googleapis.com"

  disable_on_destroy = false
}

# ---------------------------
# Generate a random password (secret value)
# ---------------------------
resource "random_password" "db_password" {
  length  = 16
  special = true
}

# ---------------------------
# Create the Secret
# ---------------------------
resource "google_secret_manager_secret" "db_password" {
  secret_id = "demo-db-password"    # logical name of the secret
  project   = var.project_id
  replication {
    auto {}

    
  }

  # replication {
  #   automatic = true
  # }

  depends_on = [google_project_service.secretmanager]
}

# ---------------------------
# Create a Secret Version with the generated value
# ---------------------------
resource "google_secret_manager_secret_version" "db_password_version" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db_password.result
}

# ---------------------------
# Service Account that will access the secret
# ---------------------------

# ---------------------------
# Grant the service account permission to read the secret
# ---------------------------
# resource "google_secret_manager_secret_iam_member" "app_sa_secret_access" {
#   secret_id = google_secret_manager_secret.db_password.id
#   role      = "roles/secretmanager.secretAccessor"
#   member    = "serviceAccount:gcp91-529@terracloudlabs91.iam.gserviceaccount.com"
#   depends_on = [ google_secret_manager_secret.db_password ]
# }




# ---------------------------
# (Optional) Data source to read secret value (for DEMO ONLY)
# ---------------------------
data "google_secret_manager_secret_version" "db_password_latest" {
  secret  = google_secret_manager_secret.db_password.id
  version = "latest"
  depends_on = [ google_secret_manager_secret.db_password ]
}

output "secret_full_name" {
  description = "Resource name of the Secret"
  value       = google_secret_manager_secret.db_password.name
}



output "db_password_from_secret_manager" {
  description = "Secret data (for demonstration ONLY; never do this in production!)"
  value       = data.google_secret_manager_secret_version.db_password_latest.secret_data
  sensitive   = true
}
