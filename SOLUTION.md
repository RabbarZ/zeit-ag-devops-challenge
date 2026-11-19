# Solution

- **First name:** _Your first name_
- **Last name:** _Your last name_

Write below each quoted prompt and replace `_Your answer here._`. You may remove the prompts, but keep the headings. Short bullets are enough; do not write your answers inside blockquotes. German or English is fine.

**Required code:** one A3 quick win, one B1 alert with loading configuration, and one C1–C6 improvement of your choice. Other proposals need an explanation, not implementation code. Use fenced code blocks with a file path and add/replace instruction, or reference the files you edited directly.

**For each implementation, include:** customer impact; file paths/code; rollout order and commands; checks with actual results or “not run” and expected results; main risk; rollback. Separate implemented work from proposals and unfinished work. No cloud apply is needed.

**Reflection:** finish with R1–R6: what you did and how long it took, what went well and badly, where the AI was wrong, where you disagree with it, and how you would deliver the solution with agents. We recommend spending about 2 hours in total.

Diagrams are optional: save them in `assets/` and link them, for example `![Target setup](assets/target.png)`. See the README for the full task and assessment criteria.

## Summary

> Give up to five bullets: top risks, what should change first, and why customers benefit. Name your selected C1–C6 implementation and locate all three required implementations (section and file paths, or “snippet below”). State which are complete, partial or not started.

_Your answer here._

## Part A: Infrastructure review

### A1. Current state

> **Discuss:** How do you rate the setup? Which decisions are good and should stay? Cite evidence. No code required.

_Your answer here._

### A2. Production risks

> **Discuss:** Rank five production risks. For each: file reference, customer impact, likelihood, and how you would notice. A table is fine. No code required.

_Your answer here._

### A3. Improvements

> **Discuss:** Quick wins (days), mid-term (weeks), long-term (quarters). For each: customer impact, effort and main risk.
>
> **Required code:** One complete quick win. Include its file paths/code, rollout, verification and rollback. Label the other changes as proposals. Further quick wins or a first mid-term implementation are optional.

_Your answer here._

### A4. Cloud-agnostic and on-premises

> **Discuss:** A hosting model for Azure, another public cloud and on-premises. Which cloud services stay or are replaced, and what do replacements cost? Who updates, backs up, restores and monitors customer installations?
>
> **Optional code:** One tenant deployment definition and its database backup job.

_Your answer here._

## Part B: Observability and 99.9 %

### B1. Know before the customer does

> **Discuss:** External checks, actionable alert signals, and an independent way to detect that monitoring itself is down.
>
> **Required code:** One loadable alert rule, with file mounts and rule-loading configuration where needed. Reuse existing signals or include new collection configuration. Explain how to trigger and resolve the alert, rollout, verification and rollback. Actual external probes, extra rules and monitoring-of-monitoring code are optional.

_Your answer here._

### B2. Who is told what

> **Discuss:** Severity, example, channel, response time and responsible person/team. Cover on-call, escalation, alert fatigue, customer communication and the fields in an actionable alert. Explain the intended route for your B1 alert; real paging is not required.
>
> **Optional code:** Notification routing and an example notification.

_Your answer here._

### B3. Performance degradation

> **Discuss:** Latency per tenant and endpoint, solver and database time, saturation, browser experience, and deployment regressions.
>
> **Optional code:** Latency/solver queries or collection of a missing signal.

_Your answer here._

### B4. User behaviour and product improvement

> **Discuss:** Useful product events and their purpose, GDPR/nDSG and customer trust, on-premises hosting, and how findings reach the product team. Avoid personal data.
>
> **Optional code:** An event schema and code sending one event.

_Your answer here._

### B5. Path to 99.9 %

> **Discuss:** Availability maths, redundancy, deployments, maintenance, backup/restore, an error-budget rule and remaining single points of failure.
>
> **Optional code:** An availability SLI query and error-budget alert.

_Your answer here._

## Part C: Maintainability

Give a few sentences for each question. Choose **one** for your third implementation, mark it “Selected implementation”, and name it in the summary. Include rollout, verification and rollback with that code. The other five need discussion only.

### C1. Environment copies and provider pins

> **Discuss:** Consistency without losing staged rollout between environments.
>
> **Code if selected:** Shared layout and Terraform for `staging` and `production`.

_Your answer here._

### C2. Cross-state reads and apply order

> **Discuss:** Risks of cross-state reads and two-round applies; a safer structure and dependency order.
>
> **Code if selected:** Restructured inputs of one environment root.

_Your answer here._

### C3. Dead code and stale imports

> **Discuss:** How to find unused code, establish whether state still uses it, and remove it safely.
>
> **Code if selected:** Discovery commands/script and the removal of what you found. Explain deletions here; hand-in records them only when `.pack-manifest.json` is present, so list them here in any case.

_Your answer here._

### C4. First-boot configuration and run commands

> **Discuss:** Drift and reproducibility after first boot; how your replacement reaches existing machines.
>
> **Code if selected:** Replace run commands for one setting made by VM setup today.

_Your answer here._

### C5. Local infrastructure checks

> **Discuss:** What do the mock-provider checks in `npm run infra.plan` and `npm run infra.verify` prove, and what remains unverified? How would you detect failed/missed checks and live drift in a real deployment? Apply and destroy are outside this pack.
>
> **Code if selected:** Local check/script changes or tests. Do not add an apply/destroy command or a GitHub workflow.

_Your answer here._

### C6. Infrastructure code in TypeScript

> **Discuss:** Team benefit, migration effort, existing state and the current status of any tool you recommend. Staying with HCL is a valid choice.
>
> **Code if selected:** One pack resource in your recommended tool, or an HCL improvement if staying with HCL.

_Your answer here._

## Roadmap (next 90 days)

> Order the proposed work, identify dependencies and say how success is measured. No additional implementation code required.

_Your answer here._

## What I would do next

> List incomplete sections or implementations, what is missing, and the next concrete step. Write “None” if nothing is unfinished; do not present planned checks as completed.

_Your answer here._

## Assumptions and open questions

> State assumptions beyond `docs/` and questions for the team. Write “None” if there are none.

_Your answer here._

## Tools and AI used

> Name the tools, documentation, AI assistants and agents you used, and what you used each one for, for example reading the pack, drafting answers, writing code or running the local checks. If you did not use AI, say so.

_Your answer here._

## Reflection

Short, honest bullets. Concrete examples from this pack and your hand-in are worth more than general statements. The reflection is not weighted in the score; the developers read it to prepare the debrief.

### R1. Work summary

> What you did and in what order, the time you actually spent, and the state of your three implementations (complete, partial, not started; checks run or not run).

_Your answer here._

### R2. What went well

> What worked, in the result and in your way of working, and why.

_Your answer here._

### R3. What went badly and troubles encountered

> What did not work or took longer than planned: unclear parts of the task, tool or setup problems, dead ends. What you did about each one.

_Your answer here._

### R4. Where the AI was wrong

> AI output that was wrong, incomplete or did not fit this pack. For each: what it said, how you noticed (file, check or documentation) and what you did instead. If you did not use AI, write “No AI used”.

_Your answer here._

### R5. Where I disagree with the AI

> Suggestions that may be technically valid but that you do not agree with for this team and product, and why (priority, cost, risk, customer impact). If you did not use AI, write “No AI used”.

_Your answer here._

### R6. Agentic delivery

> How would you deliver your proposed changes (implementations and roadmap) with AI agents in this team? Cover how you split the work into agent tasks, the context and instructions the agents get, permissions and guardrails (credentials, plan versus apply, production access), how agent output is verified and reviewed, where a human decides, and how you would tell whether the approach works.

_Your answer here._

## Developer walkthrough (15 minutes)

Use your submitted answer and code; no slides or AI assistant. This is a speaking checklist, not another written deliverable:

- **3 min:** Current setup, what should stay, top risks and customer impact.
- **3 min:** Priorities, alternatives and trade-offs.
- **6 min:** One implementation in detail: files, how it works, rollout, actual/planned verification, risk and rollback. Locate the other two implementations briefly.
- **3 min:** Remaining risks, unfinished work, assumptions and next steps, and one thing the AI got wrong.

Be ready to explain any submitted code line by line and adapt a small part live using your editor and documentation, without AI.

## Handoff checklist

- [ ] My first and last name are filled in at the top of this file.
- [ ] My three implementations are identified; partial and untested work is labelled honestly.
- [ ] Code snippets have paths; directly edited files are referenced from the matching answer section.
- [ ] My reflection (R1–R6) is filled in, including the time I spent.
- [ ] I saved everything and ran `npm run handin` (or arranged a manual handoff if it failed).
- [ ] I checked the printed included-file and deletion list, including hidden source files.
- [ ] I handed `handin/acme-planner-solution.zip` to the interviewer in the agreed way, and they confirmed receipt (or confirmed a complete manual copy).
