terraform {
  required_providers {
    nomad = {
      source  = "hashicorp/nomad"
      version = ">= 2.5.0"
    }
  }
  required_version = ">= 1.12.1"
}
