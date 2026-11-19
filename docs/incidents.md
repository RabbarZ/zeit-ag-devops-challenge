# Incidents from the last year

These six incidents are based on real events. They are condensed and anonymised, and the numbers are rounded. Use them as evidence of how the platform behaves under stress.

## 1. Containers gone after a VM reboot (August)

- **Impact:** For 17 hours, no tenant in one app environment was reachable.
- **How we found out:** A user reported the outage the next morning. The VM was running, but `docker ps` showed no containers.
- **Cause:** Azure guest patching rebooted the VM in the evening. Three things combined. Some containers had restart policy `no` after a debugging session. The compose file used `unless-stopped`, which does not restart a container that was stopped by hand. Nothing on the VM knew which tenants should be running.
- **Changes:** Base containers use `restart: always`. A boot-time service restarts all `acme-*` containers. Patch mode is an explicit Terraform variable.
- **Still open:** Tenant containers are not declared anywhere on the VM. If one is removed, nothing re-creates it.

## 2. Docker data disk not mounted, OS disk filled up (September)

- **Impact:** Tenant image pulls failed for a deployment. The OS disk reached 88 %. The fix needed about 90 seconds of container downtime.
- **How we found out:** A deployment failed with "no space left on device".
- **Cause:** The mount in `/etc/fstab` had drifted to another path. Docker then wrote 23 GB of images and containers to the OS disk, through the empty mount point. An earlier recovery job was designed to mount the disk over a directory that already held data, which would have hidden that data.
- **Changes:** A boot-time check refuses to start Docker when the data disk is missing and the mount point is not empty. Recovery scripts never mount over a directory with data.
- **Still open:** No alert on disk usage.

## 3. A provider update broke drift checks everywhere (August)

- **Impact:** The nightly drift check failed in every environment for several days. Real drift could not be seen.
- **How we found out:** The nightly job failed with plan errors.
- **Cause:** A new AzureRM provider version changed the arguments of a DNS virtual network link. The module still used the old arguments. Each environment pinned its own provider version.
- **Changes:** The module was updated and each environment was pinned again.
- **Still open:** No check runs the module against every pinned provider version before a change is merged.

## 4. Feature switch returned an error although the change was saved (August)

- **Impact:** Operators could not change feature switches for a tenant during a short database outage. The change was saved, but the API answered with HTTP 500, so operators saw an error for a change that had worked.
- **How we found out:** A support ticket.
- **Cause:** One error handler wrapped two steps: creating the signed snapshot, and pushing it to the tenant. A failed push was returned as an error, even though the change was already stored.
- **Changes:** Only a signing error now fails the request. A failed push is logged and retried by the tenant on its next poll.
- **Still open:** Licence changes still fail the request when the push fails. That is deliberate, because a licence stays inactive until the push succeeds.

## 5. Wrong advice from the solver diagnosis (August)

- **Impact:** For one customer, the planning tool reported a solver timeout and advised turning off "Fast mode", even when Fast mode was already off. The real reason was a weekly hours limit for one employee, so the advice was wrong.
- **How we found out:** A planner reported it. Support confirmed it.
- **Cause:** The diagnosis guessed the reason from availability data. It did not check weekly limits or the solver's own reason for stopping.
- **Changes:** The message now says that candidates were not selected and suggests reviewing capacity and weekly limits. It makes no claim without evidence.
- **Still open:** The solver's stop reason is not yet shown to the planner.

## 6. Near miss: a VM replacement would have wiped every tenant

- **Impact:** None. The plan review caught it.
- **How we found out:** A `terraform plan` showed that the app VM would be replaced, because the marketplace image version had changed.
- **Cause:** The VM used the `latest` image. A new image forces a replacement, and the OS disk holds every container on the VM.
- **Changes:** Image changes are ignored after creation. Changes to the first-boot setup reach existing VMs as run commands. Image upgrades are done on purpose, by tainting the VM.
- **Trade-off:** Existing VMs now drift from the code unless every change is applied to them as a run command.
