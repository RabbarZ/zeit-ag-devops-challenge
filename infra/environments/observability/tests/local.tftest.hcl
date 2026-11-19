# Local planning only. All cloud providers and remote state reads are mocked.
mock_provider "azurerm" {}
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
  target = data.terraform_remote_state.peer["control"]
  values = {
    outputs = {
      vnet_id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/rg-acme-control/providers/Microsoft.Network/virtualNetworks/rg-acme-control-vnet"
    }
  }
}

override_data {
  target = data.terraform_remote_state.peer["staging"]
  values = {
    outputs = {
      vnet_id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/rg-acme-staging/providers/Microsoft.Network/virtualNetworks/rg-acme-staging-vnet"
    }
  }
}

override_data {
  target = data.terraform_remote_state.peer["production"]
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
    condition     = output.grafana_fqdn != ""
    error_message = "The observability environment must produce a Grafana hostname."
  }
}
