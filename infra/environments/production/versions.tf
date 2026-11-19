terraform {
  required_version = ">= 1.11.4"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.81.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.8.1"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
    }
  }
}
