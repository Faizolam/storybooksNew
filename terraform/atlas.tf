provider "mongodbatlas" {
  public_key = var.mongodbatlas_public_key
  private_key = var.mongodbatlas_private_key
}

resource "mongodbatlas_cluster" "mongo_cluster" {
  project_id = var.atlas_project_id
  name       = "${var.app_name}-${terraform.workspace}"
  num_shards = 1

  replication_factor           = 3 // Use 1 for M0
  auto_scaling_disk_gb_enabled = false
  mongo_db_major_version       = "4.4" // Consider using a supported version

  provider_name         = "TENANT"
  backing_provider_name = "GCP"
  # disk_size_gb                = 10
  provider_instance_size_name  = "M0" // Ensure this is correct
  provider_region_name        = "CENTRAL_US"
}
# authorized user to access db
resource "mongodbatlas_database_user" "test" {
  username           = "storybooks-user-${terraform.workspace}"
  password           = var.atlas_uesr_password
  project_id         = var.atlas_project_id
  auth_database_name = "admin"

  roles {
    role_name     = "readWrite"
    database_name = "storybooks"
  }

}


# ip wightlist 
resource "mongodbatlas_project_ip_whitelist" "test" {
  project_id = var.atlas_project_id
  ip_address = google_compute_address.ip_address.address
}

# resource "mongodbatlas_project_ip_access_list" "test" {
#   project_id = "<PROJECT-ID>"
#   ip_address = "2.3.4.5"
#   comment    = "ip address for tf acc testing"
# }