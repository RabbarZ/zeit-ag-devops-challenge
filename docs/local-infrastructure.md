# Local infrastructure commands

**No Azure account, credentials, environment variables or remote backend are required.** These commands use the supplied Terraform configurations, mock providers and fixture state. They replace the GitHub workflows; they are not wrappers around a live Azure plan.

Requirements: Node.js 24 and Terraform **1.11.4 or newer** (tested with 1.14.7). The first run downloads the providers pinned in the lockfiles; later runs reuse `.terraform-cache/`. The Terraform minimum supports plan-time mock values used by the import fixtures.

## Run the checks

```sh
npm run infra.plan                          # display a local mocked plan for staging
npm run infra.verify                        # format, validate and plan-test all four environments
npm run infra.plan -- production            # preview another environment
npm run infra.plan -- all                   # preview all environments
npm run infra.verify -- staging production  # verify a subset
npm run infra.plan -- --dry-run              # optional: only print commands
npm run infra.plan -- --help
```

Valid environments are `control`, `observability`, `staging` and `production`. Unknown options and arbitrary Terraform arguments are rejected. Both commands return **0** when all selected local checks pass, or **1** if any check fails. A failure in one environment does not prevent checking the remaining selected environments.

## What actually runs

1. `terraform fmt -check -recursive infra`.
2. For each selected root: `terraform init -backend=false -input=false -lockfile=readonly`, followed by `terraform validate`.
3. `terraform test -filter=tests/local.tftest.hcl`. Every supplied run uses **`command = plan`**, never apply. `infra.plan` adds `-verbose` to display the plan; `infra.verify` shows test results instead.

Each root has a visible fixture at `infra/environments/<environment>/tests/local.tftest.hcl`. It supplies dummy inputs, mocks AzureRM and other external providers, and overrides every Azure remote-state lookup. The control fixture also mocks registry and DNS lookups. No Azure provider authentication or backend initialisation is performed.

The stale import blocks that staging and production used to contain, and the fixture overrides that hid them from the mock plan, were removed (see `SOLUTION.md`, C3). `bash scripts/find-dead-infra.sh` reports any new import block, unused module or unused variable. Before applying that removal against Azure, check the real state as described in C3.

Local metadata is isolated under each root's `.terraform/local-mocks/`; existing deployment state is not used. Caller `ARM_*`, `AZURE_*`, `TF_VAR_*` and `TF_CLI_ARGS*` variables are stripped from Terraform's environment so they cannot change the fixture inputs or inject CLI options. Missing, empty or apply-based fixtures fail rather than silently reporting success.

## What this does not prove

- **No live drift detection.** There is no real deployed system or remote state in this pack. Verification means local syntax, provider-schema, plan and assertion checks, not “Azure has no drift”.
- No proof of cloud API acceptance, permissions, availability, production capacity, restore correctness or import viability. These need separate checks against real systems, outside this assessment.
- No apply, destroy or saved executable plan. Terraform test may print “tearing down”; plan-only runs have not created resources to destroy.

If you move or remove resources, update the relevant mock fixture and assertions along with your change. Keep fixtures clearly separate from production configuration. `npm run validate` remains the lighter offline Compose/Terraform syntax check; it does not run these plan tests.
