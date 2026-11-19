resource_name_prefix         = "rg-acme"
location                     = "switzerlandnorth"
vnet_cidr                    = "10.0.1.0/24"
vm_size                      = "Standard_D2s_v5"
docker_disk_size_gb          = 512
pg_sku                       = "GP_Standard_D2s_v3"
pg_storage_mb                = 131072
pg_backup_retention_days     = 7
pg_geo_redundant_backup      = false
pg_high_availability_mode    = "Disabled"
acr_name                     = "acmeplanneracr"
dns_zone_name                = "planner.example"
dns_zone_resource_group_name = "acme-dns"
dns_suffix                   = "staging.planner.example"

# Staging is patched during working hours, four days before production: if a patch breaks
# something, engineers are at work to notice it before production's Saturday window.
patch_schedule = {
  start_date_time = "2026-12-01 12:00" # a Tuesday
  recur_every     = "Week Tuesday"
}
