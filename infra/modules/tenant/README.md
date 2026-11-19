# Tenant module (legacy)

Creates one tenant's DNS record and PostgreSQL database with Terraform.

**Not used.** No environment calls this module. Tenants are provisioned by the control plane's TypeScript provisioner (see `services/tenant-provisioner/src/provision-tenant.ts`). The module stays in the repository until someone decides whether to delete it or bring it back.
