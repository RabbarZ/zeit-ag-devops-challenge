# Local planning only. All cloud providers and remote state reads are mocked.
mock_provider "azurerm" {
  mock_resource "azurerm_postgresql_flexible_server" {
    override_during = plan
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/rg-acme-staging/providers/Microsoft.DBforPostgreSQL/flexibleServers/rg-acme-staging-pg"
    }
  }
}
mock_provider "random" {}
mock_provider "time" {}

variables {
  subscription_id                      = "00000000-0000-0000-0000-000000000001"
  terraform_state_resource_group_name  = "local-fixture"
  terraform_state_storage_account_name = "localfixture"
  terraform_state_container_name       = "local-fixture"
  entra_tenant_id                      = "00000000-0000-0000-0000-000000000002"
  entra_admin_group_object_id          = "00000000-0000-0000-0000-000000000003"
  entra_admin_group_name               = "local-fixture-admins"
  github_actions_principal_id          = "00000000-0000-0000-0000-000000000004"
  ssh_public_key                       = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA local-fixture"
}

override_data {
  target = data.terraform_remote_state.observability
  values = {
    outputs = {
      vnet_id       = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/rg-acme-observability/providers/Microsoft.Network/virtualNetworks/rg-acme-observability-vnet"
      vm_private_ip = "10.0.10.4"
    }
  }
}

override_data {
  target = data.terraform_remote_state.control
  values = {
    outputs = {
      vnet_id                  = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/rg-acme-control/providers/Microsoft.Network/virtualNetworks/rg-acme-control-vnet"
      vm_identity_principal_id = "00000000-0000-0000-0000-000000000005"
    }
  }
}

# Mock providers cannot import an Azure resource. Supply fixture state for the
# existing import target; the stale import block remains visible in main.tf.
override_resource {
  target = azurerm_role_assignment.control_vm_postgres[0]
  values = {
    id                   = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/rg-acme-staging/providers/Microsoft.DBforPostgreSQL/flexibleServers/rg-acme-staging-pg/providers/Microsoft.Authorization/roleAssignments/00000000-0000-0000-0000-000000000000"
    scope                = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/rg-acme-staging/providers/Microsoft.DBforPostgreSQL/flexibleServers/rg-acme-staging-pg"
    name                 = "00000000-0000-0000-0000-000000000000"
    principal_id         = "00000000-0000-0000-0000-000000000005"
    principal_type       = "ServicePrincipal"
    role_definition_id   = "/subscriptions/00000000-0000-0000-0000-000000000001/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c"
    role_definition_name = "Contributor"
  }
}

run "local_plan" {
  command = plan

  plan_options {
    refresh = false
  }

  assert {
    condition     = output.keyvault_name != ""
    error_message = "The environment must produce a Key Vault name."
  }

  assert {
    condition     = module.app.patch_window.recur_every == "Week Tuesday"
    error_message = "The app VM must have a weekly patch window on Tuesday."
  }

  assert {
    condition     = module.app.patch_window.duration == "03:00"
    error_message = "The patch window must use the 3-hour default duration."
  }

  assert {
    condition     = module.app.patch_window.vm_uses_user_window
    error_message = "The VM must hand patch timing to the maintenance configuration."
  }

  assert {
    condition     = module.app.patch_window.assigned_to_this_vm
    error_message = "The patch window must be assigned to the app VM."
  }
}
