# Acme Planner: DevOps assessment

This pack describes a fictional product, **Acme Planner**, and how it is hosted on Microsoft Azure today. Everything is anonymised: names, domains (`*.planner.example`), identifiers and hosts are invented. There are no secrets and no real systems, and you do not need access to any.

**Your task:** review the supplied setup, prioritise improvements, implement three focused changes, reflect on how you worked, and explain your decisions to the developers. We recommend spending **about 2 hours at most** on the written work and hand-in. You do not need Azure credentials, a running production system, or slides.

For a visual overview of the task, open [`OVERVIEW.html`](OVERVIEW.html) in your browser. This README is the full reference.

## In short

1. Open [`OVERVIEW.html`](OVERVIEW.html), then [`SOLUTION.md`](SOLUTION.md); it is your answer and presentation template. Fill in your first and last name at the top.
2. Follow [Orientation](#orientation), then give brief answers to A1–C6 in `SOLUTION.md`.
3. Implement **one A3 quick win, one B1 alert with its loading configuration, and one C1–C6 improvement of your choice**. Use snippets or edit the supplied files. See [Required scope](#required-scope).
4. Fill in the reflection **R1–R6**: what you did and how long it took, what went well and badly, the troubles you hit, where the AI was wrong, where you disagree with it, and how you would deliver the solution with AI agents.
5. Before the agreed hand-in deadline, save your work and run `npm run handin` from this folder. Check the printed file list, hand `handin/acme-planner-solution.zip` to the interviewer in the agreed way and wait for their confirmation of receipt. **No Git commit, push or pull request is required.**
6. In the debrief, walk the developers through your work for 15 minutes, followed by questions. You must explain the code yourself; no slides or AI assistant in the debrief.

## Required scope

Aim to hand in:

- A short summary, five ranked production risks with file references, and brief answers to A1–C6. Bullets are enough.
- **Three implementations:** one complete quick win in A3; one loadable alert rule in B1, including any file mount and rule-loading configuration it needs; and one small implementation in your chosen C1–C6 section. Reuse existing signals where possible; if you introduce a signal, include its collection configuration.
- For each implementation: the changed file paths or code, customer impact, rollout, verification (with results or explicitly marked as not run), main risk and rollback.
- A short roadmap, unfinished work, assumptions, and the tools or AI you used.
- **A reflection (R1–R6):** a summary of your work with the time you spent, what went well, what went badly and which troubles you hit, where the AI was wrong, where you disagree with the AI, and how you would deliver your proposed solution with AI agents.

**Other proposals need an explanation, not code.** The optional code suggestions under the questions are stretch work, not additional requirements. Do not try to implement the whole roadmap. Complete the three selected changes before adding extras; extra code volume is not a scoring criterion.

If you run out of time, hand in what you have and identify what is incomplete. Do not claim that an untested or partial change is finished. The optional local stack is not required.

## How it works

1. The interviewer gives you this folder, tells you the **hand-in deadline** and how to reach them.
2. You work on your own. If something about the task or the setup is unclear, ask the interviewer at any time. They answer questions about the task, not about the solution.
3. You hand in before the deadline (see [What to hand in](#what-to-hand-in)).
4. The developers read your answer before the debrief.
5. The debrief follows (see [The debrief](#the-debrief)).

## Time and deadline

- We recommend spending **about 2 hours at most**, including reading, the optional local stack and hand-in. This is a recommendation, not a stopwatch. More time does not earn more points: we prefer a focused answer with honestly marked gaps to a long one.
- Write the time you actually spent in R1.
- The agreed hand-in deadline is fixed. You may hand in early.
- An unfinished section is fine. Write under "What I would do next" what is missing and what you would have written.
- We read only what you hand in: `SOLUTION.md`, `assets/`, changed or added source files, and the deletion list. `npm run handin` collects these. Packaging warnings do not stop an unfinished submission.

## Time budget

| Step | Suggested time |
| --- | --- |
| Orientation | 15 min |
| Part A: Infrastructure review | 40 min |
| Part B: Observability and 99.9 % | 30 min |
| Part C: Maintainability | 15 min |
| Reflection (R1–R6) | 10 min |
| Review your answer and hand in | 10 min |

Keep the discussion answers brief to leave time for the three implementations and hand-in. If you fall behind, stop stretch work first.

## How we assess your work

| Part | Weight | What matters |
| --- | --- | --- |
| A: Infrastructure | 50 % | Evidence, customer impact, risk ranking, practical improvements and hosting trade-offs |
| B: Observability | 35 % | Actionable detection, notification design, performance, privacy and availability |
| C: Maintainability | 15 % | Precise, safe improvements to infrastructure code and delivery |

Each question is scored from 1 to 4: **1** missing or incorrect; **2** an idea without enough evidence, impact or trade-offs; **3** a justified answer with a practical first step; **4** a prioritised answer with measurable acceptance checks and sensible sequencing. Each part uses the average of its question scores, then the weights above apply.

For A3, B1 and your chosen C section, missing, invalid or incomplete implementation code limits that question to **2**. To score higher, include code that fits this pack and explain rollout, verification and rollback. Running the optional stack is not required; clearly distinguish actual checks from expected results. We do not penalise the absence of optional extra code.

The debrief confirms or adjusts these same question scores; it has no separate percentage. If you cannot explain a submitted section after follow-up questions, we score that question as **1**. We assess understanding, not presentation polish, choice of German or English, or whether you used AI.

The reflection (R1–R6) is not part of the weighted score. The developers read it to prepare the debrief and compare it with what you handed in. An honest account of what went wrong is worth more than a polished one.

## AI and other tools

- **Use AI fully.** AI assistants and coding agents are allowed and encouraged: for reading the pack, drafting answers, writing code and running the local checks. So are documentation, vendor material and search.
- If you let an agent run commands, keep it to this folder and the local commands in this README: no cloud apply, no contact with the fictional hosts, no credentials.
- Name what you used, and for what, under "Tools and AI used" in `SOLUTION.md`, and reflect on it in R4–R6.
- **You explain your answer yourself.** In the debrief, the developers ask about any point in your answer: why it matters, how it works, what it costs. "The AI suggested it" is not an answer. You can have your `SOLUTION.md` open, but not an AI assistant.
- Check what an AI tells you against the files. This pack contains details that a generic answer gets wrong. Write down what you caught in R4.

## Code we expect

Code is required only for the three implementations in [Required scope](#required-scope). It must use real file paths, resources and service names from this pack and syntax the tool accepts; pseudo-code is not enough. You can deliver code in two ways, and mix them:

1. **Change the pack's files directly**, or add new files next to them, for example in `infra/` or `runtime/`. `npm run handin` collects source changes, including hidden configuration files, and records deleted files. The developers compare them with the original pack.
2. **Write snippets in `SOLUTION.md`**, as fenced code blocks with the language. Start each block with a comment that names the file and says whether the code replaces or adds lines:

   ````markdown
   ```hcl
   # infra/environments/staging/terraform.tfvars: replace
   vm_size = "Standard_D4s_v5"
   ```
   ````

For every implementation, write next to the code or file reference in `SOLUTION.md`:

- **What** it changes, and **why**: the customer impact.
- **How you roll it out**: the commands, their order, and which environment goes first.
- **How you verify it**: for example the expected `terraform plan` result, a query, or a `curl`.
- **The main risk**, and how you roll it back.

Prove it where you can. For Terraform changes, run `npm run validate` if the tools are available and report failures or skipped checks. Otherwise state that you did not run it and give the expected check; a skipped check is not a pass. The [local stack](#optional-run-it-locally) can help you try scrape configs, queries and alert rules against real data, but starting it is optional. Do not run a cloud apply or contact the fictional hosts.

A few complete, correct changes are worth more than many fragments. When only a few lines change, do not paste the whole file.

## Orientation

1. `docs/product.md`, then `docs/architecture.md`, then `docs/incidents.md`
2. Skim `infra/environments/production/main.tf`, `infra/modules/app-environment/main.tf`, `infra/modules/vm/main.tf`, `runtime/app/compose.yml` and `runtime/observability/compose.yml`

You do not need to read every file.

## Part A: Infrastructure review

Read the Terraform, the VM bootstrap, the compose files and the incidents.

- **A1. Current state.** How do you rate the setup today? Which decisions are good and should stay?
- **A2. Production risks.** Name the five biggest risks for production. For each, describe what happens to customers (tenants, planners, employees), how likely it is, and how you would notice it. **Code:** No code needed. Name the file for each risk.
- **A3. Improvements.** Propose changes as quick wins (days), mid-term (weeks) and long-term (quarters). For each, state the customer impact, the effort and the main risk of doing it. **Required code:** One complete quick win. **Optional extra:** Further quick wins or the first concrete step of a mid-term change.
- **A4. Cloud-agnostic and on-premises.** Some customers want Acme Planner on their own hardware, and we do not want to depend on one cloud provider. Describe a hosting model that runs on Azure, on another public cloud and on-premises. Say which cloud services it keeps, which it replaces, and what the replacements cost you. Describe how a customer installation is updated, backed up and monitored. **Optional code:** A tenant deployment definition and its database backup job.

## Part B: Observability and 99.9 %

- **B1. Know before the customer does.** How do you learn that something is broken, or getting slower, before a customer reports it? Cover checks from outside the network, the signals you would alert on, and how you learn that the monitoring itself is down. **Required code:** One alert rule in a format the stack can load (Prometheus, Loki or Grafana alerting), with its loading configuration and any new signal collection it needs. Describe how to trigger and resolve it. **Optional extra:** Implement the external check, two more alert rules or independent monitoring-of-monitoring.
- **B2. Who is told what.** Design the notification channels. Cover severity levels and channels, who is on call, escalation when nobody answers, alert fatigue, and what an actionable alert contains. **Optional code:** Routing configuration and an example notification. The B1 rule need not deliver a real page; explain the intended route here.
- **B3. Performance degradation.** Which measurements show slowness early? Cover latency per tenant and endpoint, solver and database time, saturation, browser experience, and deployment regressions. **Optional code:** Latency and solver queries, or collection of a missing signal.
- **B4. User behaviour and product improvement.** Which product data would help decide what to build or fix? Cover purpose, GDPR and Swiss nDSG, customer trust, on-premises hosting, and how results reach the product team. **Optional code:** An event schema and code that sends one event without personal data.
- **B5. Path to 99.9 %.** That target allows about 43 minutes of downtime per month. Cover redundancy, deployments, maintenance, backup and restore, and the error-budget rule agreed with the business. Which single points of failure remain? **Optional code:** An availability SLI query and error-budget alert.

## Part C: Maintainability of the infrastructure code

Give a few sentences for each question. **Choose one C1–C6 question for your third required implementation**, name your choice in the summary, and include the code described for it. Code for the other five is optional.

- **C1.** Several environment roots are copies of each other, and each pins its own AzureRM version. How would you keep them consistent while rolling out to one environment first? **Code if chosen:** The layout and Terraform for `staging` and `production`.
- **C2.** Environments read each other's Terraform state, and networking needs two apply rounds. What is the risk, and how would you restructure it? **Code if chosen:** The restructured inputs of one environment root.
- **C3.** How would you find unused code and stale import blocks and remove them safely? **Code if chosen:** Discovery commands or a script, and the removal of what you found.
- **C4.** VM setup runs once at first boot; later changes use run commands. What problems does this create, and what would you change? **Code if chosen:** A replacement for one setting made by VM setup today.
- **C5.** What makes the local `infra.plan` and `infra.verify` checks trustworthy? Which checks do you trust least, and how would you notice a failed or missed verification run? **Code if chosen:** Local check/script changes or tests. Do not add an apply/destroy command or a GitHub workflow.
- **C6.** Would infrastructure code in TypeScript help this team? What would migration cost, and what happens to state? Check the current status of any tool you mention. **Code if chosen:** One resource from this pack in your recommended tool, or an HCL improvement if you recommend staying with HCL.

## Ground rules

- Do not invent facts about the product beyond what is in `docs/`. Write any assumption you need into `SOLUTION.md`.
- Do not contact the fictional cloud systems or run a cloud apply. Local tests and documentation searches are allowed.
- Write and present in German or English, as you prefer.
- Please do not share this pack or your answer outside the interview.

## Local infrastructure checks

There are **no GitHub workflows**. These commands run locally with the supplied fixtures, **without Azure credentials, environment variables or a remote backend**:

```sh
npm run infra.plan                    # display a mocked Terraform plan for staging
npm run infra.verify                  # validate and run plan-only tests for all four environments
```

You need Node.js 24 and Terraform 1.11.4 or newer. The first run downloads the pinned providers from the Terraform registry; subsequent runs reuse the local cache. No Azure account or setup values are needed.

`infra.plan` displays the real Terraform resource graph using mock providers and fixture remote-state outputs via `terraform test` with `command = plan`. `infra.verify` checks formatting and configuration and runs the same plan-only tests for all four environments. Pass environment names to select another scope, for example `npm run infra.plan -- production` or `npm run infra.verify -- staging production`.

Both exit **0** when local checks pass and **1** if a check fails. They never apply, destroy or save a plan. **They do not check live Azure drift:** there is no deployed system in this pack. `--dry-run` is optional and only prints commands. See [Local infrastructure commands](docs/local-infrastructure.md) for fixtures and limitations.

## What to hand in

1. **Your answer** goes into `SOLUTION.md`. Fill in your first and last name at the top, and keep its headings. Write below the visible prompts; remove or leave the prompts, but replace `_Your answer here._`. Bullets are fine. Mark unused sections as unfinished rather than deleting their headings.
2. **Your code** goes into `SOLUTION.md` as snippets, or directly into the pack's files (see [Code we expect](#code-we-expect)). Refer to changed files from the matching section of `SOLUTION.md`, so we know why you changed them.
3. **Diagrams** go into `assets/`, linked from `SOLUTION.md`. Any image format works. A photo of a paper sketch is fine.
4. **Before the deadline**, save all files and run:

   ```sh
   npm run handin
   ```

   It packs `SOLUTION.md`, `assets/` and changed or added source files into `handin/acme-planner-solution.zip`. `HANDIN.json` inside the ZIP records the baseline commit, included files and deletions (renames appear as a deletion and an addition). If your folder has no `.pack-manifest.json` (a plain ZIP download), it packs the whole folder instead, and `HANDIN.json` records no changes: the interviewer works them out, so list any files you deleted in `SOLUTION.md`.

5. **Check the printed file and deletion list.** The command gives reminders for a missing name, for empty or missing headings and for required implementation sections without a code block or a reference to a changed file. These are reminders, not syntax checks or proof of completeness; they do not block hand-in.
6. **Hand the ZIP to the interviewer in the agreed way and wait for their confirmation of receipt.** The ZIP is the submission, not your local folder or a Git branch. Do not continue editing after you hand in. If you hand in early, tell the interviewer that this is your final submission.

If `.pack-manifest.json` is in the folder (the interviewer's candidate ZIP contains it), `npm run handin` uses it to find your changes exactly, so do not edit or delete it. A plain ZIP download works without it. Git, `npm install`, Docker and Terraform are not needed for hand-in. If npm is unavailable but Node works, use `node scripts/handin.mjs`.

Generated folders (`node_modules/`, `.terraform/`, `.terraform-cache/`, `dist/`, `handin/`), Git metadata, interviewer files, `.env`/`.env.*`, Terraform state and plan files, crash logs and `.DS_Store` are excluded. Do not put your answer in those locations or add credentials anywhere. Use regular files, not symbolic links. All other source files, including hidden files, can be collected; inspect the printed list for accidental additions.

**If packaging fails:** tell the interviewer before the deadline and hand over the **whole working folder** instead, for example as a ZIP made with your system's own tool. Include changed files, hidden source files and `.pack-manifest.json` if it is there, not just `SOLUTION.md`, and leave out the generated/private files above. The interviewer compares the copy with the original pack, including deletions. Wait for their confirmation of receipt; a failed command or an older ZIP is not a successful hand-in.

## The debrief

The debrief takes 45 to 60 minutes, with developers from the team that runs Acme Planner.

- **About 15 minutes: you walk us through your submitted answer.** Show `SOLUTION.md` and your code; no slides needed. Use this order (also in the template):
  1. **3 minutes:** the current setup, what should stay, and your top risks and customer impact.
  2. **3 minutes:** your priorities, trade-offs and why you did not choose alternatives.
  3. **6 minutes:** one implementation in detail: file paths, how it works, rollout, actual versus planned checks, risk and rollback. Briefly locate your other two implementations.
  4. **3 minutes:** remaining risks, unfinished work, assumptions, next steps, and one thing the AI got wrong.
- **The rest: our questions.** Expect questions like these:
  - Why is your top risk first? Who is affected, and how would you notice?
  - What would you do in your first week, before changing anything?
  - Which change would you advise the team *not* to make, and why?
  - A short scenario, for example a customer reports a problem but no alert fired. Talk us through what you look at, in which order.
  - Any point in your answer, including parts an AI wrote: how does it work, what does it cost, what could go wrong?
  - Your reflection: what the AI got wrong and how you noticed, and how you would let agents deliver your next change safely.
  - One of your code changes, line by line: what each part does, how you apply it, how you check that it worked, and how you roll it back.
  - A small variation of one of your snippets, written live, for example for another environment or another threshold. You may use your editor and the documentation, but not an AI assistant.
- Explain it so that a developer who has not read the Terraform can follow it: what changes for the customer, and the trade-off. Tool names alone are not an explanation.

## What is in the pack

| Path | What it is |
| --- | --- |
| `OVERVIEW.html` | Visual overview of the task; open it in a browser |
| `SOLUTION.md` | Template for your answer |
| `assets/` | Your diagrams (empty) |
| `.pack-manifest.json` | Checksums of the original files, in the interviewer's candidate ZIP. When present, `npm run handin` uses it to record your changes exactly |
| `docs/` | Product, architecture (with a diagram as `architecture.png`) and six condensed incidents |
| `infra/` | Terraform: modules and four environment roots |
| `runtime/` | Compose files and configs for the app, control and observability VMs |
| `services/demo-api/` | Node.js stand-in for a tenant API, with OpenTelemetry |
| `services/tenant-provisioner/` | Excerpt of the TypeScript tenant provisioner |
| `local/` | Optional local stack (compose file, Caddy and Postgres config) and the k6 load test |
| `scripts/` | Local plan/verification commands and helpers behind the other `npm` commands |

The VM configs, Terraform and local checks follow the real system but are simplified. Some values are placeholders. Infrastructure apply and destroy are not included.

## Optional: run it locally

You do not need to run anything to answer the questions. The local stack lets you watch how telemetry flows and try failure modes. The time it takes counts toward the recommended 2 hours.

**Requirements**, on Windows, macOS or Linux:

- Node.js 24 or newer with npm. You also need it for `npm run handin`.
- Docker with Compose v2: Docker Desktop on Windows (with the WSL 2 backend) and macOS, or Docker Engine with the Compose plugin on Linux. `docker ps` must work in your terminal without errors.
- Ports 29999, 30000 and 30001 must be free.
- `npm run validate`, `infra.plan` and `infra.verify` need Terraform 1.11.4 or newer (tested with 1.14.7).

The commands are the same in PowerShell, Command Prompt, Terminal, bash and zsh. Run them in this folder.

```sh
npm install                  # optional: installs the two TypeScript services, only needed for npm run typecheck and your editor
npm start                    # builds and starts the whole stack, then waits until both tenants are healthy
npm run load                 # sends traffic to both tenants with k6 (runs for 2 minutes)
npm run stop -- postgres     # stops one service and lets you watch what happens
npm start -- postgres        # starts that service again
npm stop                     # stops everything and deletes the volumes
```

The first `npm start` takes several minutes because Docker builds the demo API and pulls the images. It prints the URLs when everything is ready.

At the end, `npm run load` prints its thresholds. The `solve` threshold often fails, because the stand-in solver has a slow tail on purpose. k6 then exits with an error, and npm reports it. That is a result to look at, not a broken setup.

| Service name | What it is |
| --- | --- |
| `tenant-a`, `tenant-b` | Two tenant API containers, each with its own database |
| `caddy` | Reverse proxy in front of the tenants |
| `postgres`, `redis` | Shared database and cache |
| `alloy`, `loki`, `tempo`, `prometheus`, `grafana` | Observability stack |

Use these names with `npm run stop -- <service>` and `npm start -- <service>`. You can name several services at once.

| What | Where |
| --- | --- |
| Tenant a and b | http://a.localhost:29999/api/items and http://b.localhost:29999/api/items. Health: `/api/health`. |
| Grafana | http://localhost:30000 (admin / admin) |
| Prometheus | http://localhost:30001 |

If `*.localhost` does not resolve on your machine, send the host name as a header: `curl -H "Host: a.localhost" http://localhost:29999/api/health`. In Windows PowerShell, type `curl.exe` instead of `curl`.

Other commands:

- `npm run logs` follows the logs of all services. Stop it with Ctrl+C.
- `npm run typecheck` type-checks both TypeScript services (after `npm install`).
- `npm run validate` checks the compose file and runs `terraform fmt`, `init -backend=false` and `validate` for every environment. It needs no cloud access, but the first run downloads the AzureRM provider (a few hundred MB). It skips a check with a warning if Docker or Terraform is not installed.

**If something does not work:**

- *Port is already allocated:* another program uses 29999, 30000 or 30001. On Windows, the system can also reserve ports: `netsh interface ipv4 show excludedportrange protocol=tcp` lists them.
- *Cannot connect to the Docker daemon:* start Docker Desktop, or the Docker service on Linux, and try again.
- *A tenant does not become healthy:* run `npm run logs`, then `npm stop` and `npm start` for a clean start.
- Still stuck? Ask the interviewer. Do not spend your time on the setup; the stack is optional.

The local stack is a stand-in. It mirrors one app VM and the observability VM in a single compose project. It does not model production capacity or security.
