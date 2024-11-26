terraform {
  backend "gcs" {
    bucket = "devopsstorybooks-terraform"
    prefix = "/state/storybooks"
  }
  required_providers {
    google={
        source = "hashicorp/google"
        version = "~> 3.38"
    }

   mongodbatlas = {
      source = "mongodb/mongodbatlas"
      version = "0.9.1"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  
  }
}

