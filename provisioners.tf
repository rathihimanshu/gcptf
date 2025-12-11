
provider "google" {
  project = "terracloudlabs91"
  region  = "us-central1"
}


/* optional: separate provider for EU region (for provider meta-arg demo later) */

resource "google_compute_network" "demo" {
  name                    = "demo-prov-meta-net1"
  auto_create_subnetworks = false
}





