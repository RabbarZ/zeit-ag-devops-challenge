# Local planning only. Azure lookups and every remote state read are mocked.
mock_provider "azurerm" {
  mock_data "azurerm_container_registry" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/acme-shared/providers/Microsoft.ContainerRegistry/registries/acmeplanneracr"
    }
  }
  mock_data "azurerm_dns_zone" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/acme-dns/providers/Microsoft.Network/dnsZones/planner.example"
    }
  }
}
mock_provider "time" {}

variables {
  terraform_state_resource_group_name  = "local-fixture"
  terraform_state_storage_account_name = "localfixture"
  terraform_state_container_name       = "local-fixture"
  entra_tenant_id                      = "00000000-0000-0000-0000-000000000002"
  entra_admin_group_object_id          = "00000000-0000-0000-0000-000000000003"
  github_actions_principal_id          = "00000000-0000-0000-0000-000000000004"
  ssh_public_key                       = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA local-fixture"
}

override_data {
  target = data.terraform_remote_state.observability
  values = {
    outputs = {
      vnet_id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/rg-acme-observability/providers/Microsoft.Network/virtualNetworks/rg-acme-observability-vnet"
    }
  }
}

override_data {
  target = data.terraform_remote_state.app["staging"]
  values = {
    outputs = {
      vnet_id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/rg-acme-staging/providers/Microsoft.Network/virtualNetworks/rg-acme-staging-vnet"
    }
  }
}

override_data {
  target = data.terraform_remote_state.app["production"]
  values = {
    outputs = {
      vnet_id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/rg-acme-production/providers/Microsoft.Network/virtualNetworks/rg-acme-production-vnet"
    }
  }
}

run "local_plan" {
  command = plan

  plan_options {
    refresh = false
  }

  assert {
    condition     = output.keyvault_name != ""
    error_message = "The control environment must produce a Key Vault name."
  }
}
