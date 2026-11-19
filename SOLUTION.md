# Solution

- **First name:** Kilian
- **Last name:** Hürlimann

## Summary

- **Top risks:** one app VM carries all ~40 production tenants; no alerting, so customers find outages (incident 1: 17 h).
- **First:** detect outages ourselves (B1), stop surprise reboots (A3), then make tenants and the database recoverable.
- **A3 – patch window:** complete. `infra/modules/vm/`, `infra/environments/{staging,production}/`.
- **B1 – TenantDown alert:** complete, tested locally. `runtime/observability/alloy/`, `runtime/observability/prometheus/`.
- **C3 – stale imports and dead code (selected):** complete. `infra/environments/{staging,production}/`, `scripts/find-dead-infra.sh`.

## Part A: Infrastructure review

### A1. Current state

Good base for a small team, but one broken part can take all customers down.

**Keep:**
- All infrastructure is in code (Terraform), and staging and production are built from the same code.
- The database is not reachable from the Internet.
- Passwords are in a Key Vault, not in files.
- Fixes from past incidents are already built in (containers restart after a reboot; Docker won't start if its disk is missing).

**Weak:**
- Everything runs on one machine per environment.
- No alerts: customers find problems first.
- Some machines have more rights than they need.

### A2. Production risks

| # | Risk | File | Customer impact | Likelihood | How we notice |
|---|---|---|---|---|---|
| 1 | One app VM; tenants not declared anywhere; Azure reboots it when it wants | `infra/modules/vm/main.tf` | All tenants down | High | Today: customers. Now: B1 |
| 2 | No alert rules, no Alertmanager | `runtime/observability/prometheus/prometheus.yml` | Outages last until someone complains | High | We don't |
| 3 | PostgreSQL: one server without a standby copy, 7-day backups, restore never tested | `infra/environments/production/terraform.tfvars` | All tenants down for hours | Medium | Health checks fail (B1) |
| 4 | SSH open to the Internet; WAF only logs; control VM has very broad rights | `infra/modules/app-environment/main.tf`, `infra/environments/control/main.tf` | Data breach across all tenants | Medium | Not at all |
| 5 | Loki has no retention; shared 128 GB monitoring disk fills | `runtime/observability/loki/local-config.yaml` | Monitoring goes blind | Medium | No disk alert |

### A3. Improvements

| When | Change | Customer impact | Effort | Main risk |
|---|---|---|---|---|
| Days | **Patch window (implemented)** | No reboots during working hours | 30 min | Window rejected by Azure |
| Days | Close SSH from the Internet; Loki retention; DB backups 7 → 35 days | Safer, monitoring stays up | ~2 h | Locking out operators |
| Weeks | Declare tenants on the VM, re-create them at boot | Lost tenant comes back by itself | 3–5 days | Bug restarts tenants |
| Weeks | PostgreSQL standby copy in a second datacenter (`pg_high_availability_mode = "ZoneRedundant"`) + monthly restore test | DB failure costs ~2 minutes, not hours | 1–2 days, ~2× DB cost (needs budget approval) | Short errors during the switch |
| Quarters | Two app VMs behind a load balancer | Reboots and deploys without downtime | 4–6 weeks | Sessions, routing |

#### Implemented quick win: weekly patch window

- **What and why:** Azure still patches, but only in our window. Staging **Tuesday 12:00–15:00** (patched first, while engineers are at work). Production **Saturday 22:00–01:00**, far from the Monday peak.
- **Files:**
  - `infra/modules/vm/variables.tf`: `patch_schedule`; rejects Monday windows.
  - `infra/modules/vm/main.tf`: maintenance configuration + assignment; VM flag set only when a window exists.
  - `infra/modules/app-environment/*`, `infra/environments/{staging,production}/*.tf`, `terraform.tfvars`: pass and set the windows.
  - `infra/environments/{staging,production}/tests/local.tftest.hcl`: 4 assertions.
- **Rollout:** staging first; the plan must show 2 to add and the VM updated in place (no replace). After one good Tuesday, production.
- **Checks run:** `npm run infra.verify` passes (all 4 environments); Monday window rejected; `patch_schedule = null` plans. **Not run:** real plan against Azure.
- **Risk:** Azure rejects the window or replaces the VM; any replace in the plan stops the rollout.
- **Rollback:** `patch_schedule = null` and apply.

### A4. Cloud-agnostic and on-premises

- Same container images everywhere, deployed with Kubernetes (Azure, other cloud, or k3s on customer hardware).
- **Cost:** we run PostgreSQL ourselves on-prem; three platforms to test with one DevOps engineer.
- **Updates, backup, monitoring:** customer installs signed releases with our runbook; backup job included, restore test twice a year; monitoring config ships with it.

## Part B: Observability and 99.9 %

### B1. Know before the customer does

- **Outside-in:** check every tenant's health endpoint (implemented); later one check from outside Azure.
- **Alert on:** tenant down, error rate, slow responses, disk full, certificate expiry.
- **Monitoring of monitoring:** `TenantProbesMissing` (implemented); later a watchdog alert to an external service.

#### Implemented: TenantDown alert

- **What:** Alloy calls each tenant's `/api/health` every 30 s, like a browser (DNS, TLS, Caddy, container, database). Prometheus alerts when a tenant fails for 2 minutes.
- **Files:**
  - `runtime/observability/alloy/config.alloy`: reads the tenant list, runs the checks, sends results to Prometheus.
  - `runtime/observability/alloy/probe-targets.json` (production list, empty: tenant names not given), `local/alloy/probe-targets.json` (local tenants).
  - `runtime/observability/prometheus/rules/tenant-availability.yml`: `TenantDown` (failing 2 min, critical) and `TenantProbesMissing` (no results 10 min, warning).
  - `runtime/observability/prometheus/prometheus.yml` (`rule_files`), `runtime/observability/compose.yml`, `local/compose.yml` (mounts).
- **Trigger / resolve:** stop the database → fires after ~2 min; start it → resolves.
- **Rollout:** staging first. Fill the tenant list, copy `runtime/observability/` to the VM, `docker compose up -d alloy prometheus`. Then production.
- **Checks run:** `promtool check rules` OK; Alloy syntax OK; compose config OK. Local test: stopped postgres 15:25:42 → firing 15:27:56; started 15:28:15 → resolved 15:28:42.
- **Local difference:** locally the checks call the containers directly (no Caddy); production uses the public HTTPS URL.
- **Risk:** false alarms or an outdated tenant list. **Rollback:** `git revert` and redeploy; only monitoring changes.

### B2. Who is told what

| Severity | Example | Channel | Response |
|---|---|---|---|
| Critical | TenantDown in production | Page + Teams | 15 min |
| Warning | Disk > 80 %, slow responses | Teams + ticket | Same day |
| Info | Staging alerts | Teams | Next day |

- **On-call:** weekly rota of the 4 backend/DevOps engineers, business hours first. No answer in 15 min → second person.
- **Less noise:** page only when customers are affected; everything else becomes a ticket.
- **An alert says:** what, which tenant, since when, impact, link to dashboard and runbook.
- **B1 route:** production → page; staging → Teams only.

### B3. Performance degradation

- Response time per tenant and endpoint (p95), compared to last Monday.
- Solver run time and timeouts; database query time.
- VM CPU, memory and disk; Redis memory (full Redis logs users out).
- Browser speed and errors (real-user monitoring).
- Compare upgraded vs. not-yet-upgraded tenants after a deploy.

### B4. User behaviour and product improvement

- **Events:** plan solved (duration, result), plan published, shift swaps, feature usage.
- **Privacy:** only tenant ID and role; no names, e-mails or absence reasons; data stays in Switzerland; agreed in the customer contract; customers can switch it off.
- **On-prem:** off by default. **Product team:** monthly dashboard review.

### B5. Path to 99.9 %

- 99.9 % = at most about 43 minutes of downtime per month.
- **Database:** today one server. If it fails, all tenants are down for hours. A standby copy in a second datacenter takes over in about 2 minutes.
- **App VMs:** two VMs behind a load balancer, each big enough to carry the full load alone. If one fails or reboots, the other takes over.
- **Deployments and patching:** one VM at a time, so customers don't notice.
- **Backup:** test a restore every month, so we know it works within 4 hours.
- **Error budget:** if the 43 minutes are used up in a month, no new features until next month, only stability work.
- **Still single:** the Azure region and the monitoring VM.

## Part C: Maintainability

### C1. Environment copies and provider pins

- Provider versions differ (4.80.0 vs 4.81.0) by accident, not by decision.
- Keep separate environments, but one list of versions; staging gets a new version first, production a week later.
- Test shared modules against every pinned version (incident 3).

### C2. Cross-state reads and apply order

- **Risk:** each environment can read all of another's state (including secrets); new environments need two applies; a missing state silently removes a network link.
- **Fix:** one network root owns all networks and links, applied first; other roots get IDs as normal inputs.

### C3. Dead code and stale imports

**Selected implementation.**

- **What and why:** staging and production had an `import` block pointing at a role assignment ID that was never imported. A real `terraform plan` fails on it, which blocks all infrastructure changes. The local tests hid this with special overrides. `infra/modules/tenant` was unused.
- **Discovery:** `scripts/find-dead-infra.sh` lists unused modules, `import` blocks and unused variables. On the original pack it finds exactly the tenant module and both imports.
- **Removed:**
  - `infra/environments/{staging,production}/main.tf`: the `import` block.
  - `infra/environments/{staging,production}/variables.tf`: `subscription_id` (only used by the import).
  - `infra/environments/{staging,production}/tests/local.tftest.hcl`: the overrides that hid it.
  - **Deleted files:** `infra/modules/tenant/README.md`, `infra/modules/tenant/main.tf`, `infra/modules/tenant/variables.tf`.
- **Rollout (staging first):** check the real state before applying:
  1. `terraform state list | grep control_vm_postgres`: if present, nothing changes.
  2. If not: `az role assignment list --scope <pg-server-id>`. If it exists, import it with the real ID first; if not, the plan creates it.
- **Checks run:** `npm run infra.verify` passes; the script reports "Nothing found." **Not run:** plan against real Azure.
- **Risk:** the role assignment exists in Azure but not in state → create fails (step 2 prevents it). **Rollback:** `git revert`.

### C4. First-boot configuration and run commands

- Changes after first boot never reach existing VMs automatically, and Terraform hides that drift.
- **Fix:** VM config as a versioned bundle, applied on every deploy and reporting drift; later prebuilt images.

### C5. Local infrastructure checks

- **Proves:** syntax, provider schema, plan graph, assertions. **Doesn't prove:** Azure accepts it, permissions, drift.
- **Trust least:** the fixture overrides (C3 shows they hid a real failure).
- **Missed runs:** alert if the last successful run is older than 24 h; nightly read-only plan for drift.

### C6. Infrastructure code in TypeScript

- **Stay with HCL:** small setup, one DevOps engineer.
- CDK for Terraform was archived by HashiCorp in December 2025. Pulumi works but needs every resource imported again: risky (incident 6: replacing the VM wipes all tenants).

## Roadmap (next 90 days)

- **Weeks 1–2:** B1 + on-call, patch window, C3, close SSH, Loki retention. *Success: the next outage is found by an alert.*
- **Weeks 3–6:** declared tenants, PostgreSQL standby copy, first restore test. *Success: restore measured under 4 h.*
- **Weeks 7–12:** network restructure (C2), second app VM, deploys without downtime. *Success: monthly availability reported per tenant.*

## What I would do next

- B1: fill the production tenant list, add Alertmanager routing, add an external check.
- A3 and C3: real `terraform plan` against staging.
- Patch windows for the monitoring and control VMs.

## Assumptions and open questions

- Assumption: Saturday night has the lowest traffic.
- Question: is the old `github_actions_principal_id` still used? It has broad rights.

## Tools and AI used

- **Claude Code (Claude Opus 5.5) in VS Code:** reading the pack, planning, writing code and this document, running checks. I reviewed and committed each feature separately.
- **Tools:** Terraform 1.14.7, Node.js 24, Docker, promtool 3.2.1, Alloy 1.20.1.

## Reflection

### R1. Work summary

- **Time:** 2 h 30 min.
- **Order:** plan with the agent → install tools → A3 → C3 → B1 (with local stack) → this document.
- **State:** all three complete; local checks run; nothing run against real Azure.

### R2. What went well

- Finding gaps in the implementation, e.g. the stale import hidden by the test overrides.
- One feature per commit kept each change easy to review.

### R3. What went badly and troubles encountered

- Working on a VM and testing everything with the agent: Node, Terraform and Docker had to be installed first, which took more time.
- After installing Docker, it only worked without sudo after a new login.

### R4. Where the AI was wrong

- **Docker:** the AI said a new terminal would pick up the Docker group. In VS Code it did not; `hello-world` failed without sudo.
- **Terraform test:** the AI's first assertions pointed at resources inside nested modules. Terraform rejected them; `infra.verify` caught it.

### R5. Where I disagree with the AI

- **Staging patch window:** the AI proposed Tuesday night. I changed it to Tuesday noon, so engineers are at work if a patch breaks something, days before production.

### R6. Agentic delivery

- One agent task = one change = one commit, as done here.
- Agents get the repo rules (no apply, staging first, which checks to run) but no Azure write access.
- The agent must show check results; a human reads the plan and decides about production, permissions and data.
- **Is it working:** share of agent changes merged without rework, and changes that caused incidents.

## Developer walkthrough (15 minutes)

- **3 min:** Current setup, what should stay, top risks and customer impact.
- **3 min:** Priorities, alternatives and trade-offs.
- **6 min:** One implementation in detail: files, how it works, rollout, actual/planned verification, risk and rollback. Locate the other two implementations briefly.
- **3 min:** Remaining risks, unfinished work, assumptions and next steps, and one thing the AI got wrong.

## Handoff checklist

- [x] My first and last name are filled in at the top of this file.
- [x] My three implementations are identified; partial and untested work is labelled honestly.
- [x] Code snippets have paths; directly edited files are referenced from the matching answer section.
- [x] My reflection (R1–R6) is filled in, including the time I spent.
- [x] I saved everything and ran `npm run handin` (or arranged a manual handoff if it failed).
- [x] I checked the printed included-file and deletion list, including hidden source files.
- [ ] I handed `handin/acme-planner-solution.zip` to the interviewer in the agreed way, and they confirmed receipt (or confirmed a complete manual copy).
