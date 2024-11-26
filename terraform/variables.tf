### GENERAL
variable "app_name" {
  type = string
}

### ATLAS KEY
variable "atlas_project_id" {
  type = string
}

variable "mongodbatlas_public_key" {
  type = string
}

variable "mongodbatlas_private_key" {
  type = string
}

variable "atlas_uesr_password" {
  type = string  
}



### GCP machine
variable "gcp_project_id" {
  type = string
}

variable "gcp_machine_type" {
  type = string
}

### CLOUDFLARE
variable "cloudflare_api_token" {
  type = string
}

variable "domain" {
  type = string
}
