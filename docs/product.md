# Acme Planner: product context

Acme Planner is a multi-tenant SaaS for capacity and shift planning. Each customer is a company with 20 to 2,000 people. Examples of customers: a hospital group, a logistics company, a regional service provider.

## What customers do with it

- **Planners** define demand (shifts, required skills, opening hours) and run the solver to assign people to shifts. A typical run takes 5 to 30 seconds and is cut off after 60 seconds.
- **Managers** review a plan and publish it. Publishing sends schedules to employees and their calendars.
- **Employees** look at their schedule, request absences and swap shifts.
- **Tenant administrators** manage users, roles and feature switches for their company.

Planning peaks on Monday between 07:00 and 09:00, when the week's plan is finalised. A plan that cannot be published before the shifts start costs the customer money and goodwill. Any outage on a Monday morning is treated as a top-severity event.

## Figures

The numbers below are illustrative for this exercise. They are not measured data from a real system.

| Figure | Value |
| --- | --- |
| Tenants (customers) | about 40. Each runs in its own container and database. |
| Active users | about 5,000 per month |
| Solver runs | about 800 per day; about 150 per hour on Monday mornings |
| Plan publications | about 1,200 per month |
| Concurrent browser sessions | about 900 at the Monday peak |
| Personal data | names, contact details, absences, shift assignments. Some absence reasons are sensitive. |
| Data location | Switzerland North for all customers. EU customers require data to stay in the EU. |
| Releases | about two production deployments per week. Tenant rollouts happen separately, per customer. |

## Commitments

- Contract: 99.5 % availability per calendar month for production. The business wants 99.9 % as the next target.
- Recovery targets agreed with the largest customers: at most 4 hours to restore service after a major failure, and at most 1 hour of data loss.
- Some customers ask for an on-premises installation of the same product. Two are running today. More are in negotiation.

## Compliance

- Personal data is processed under the GDPR and the Swiss federal act on data protection (nDSG). The customer is the controller. Acme is the processor.
- Logs, traces and metrics must not contain personal data such as names, e-mail addresses or absence reasons. Tenant identifiers are allowed.
- Product analytics must respect the same rules and must not be a surprise to customers.

## Team

Three backend engineers, four frontend engineers, one DevOps engineer, one product owner. There is no formal on-call rota yet.
