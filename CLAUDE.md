# FDE Capstone — Aria (Intelligent Diner Support Agent)

## Org
- Alias: `FdeCap`
- Always use `--target-org FdeCap` on all `sf` commands
- Never hardcode Salesforce record IDs — always use dynamic queries

## Project
Online hospitality platform. Building Aria, an Agentforce ASA (Live channel) for booking modifications, cancellations, restaurant info, and escalation to human agents.

## Confirmed Products
- Agentforce (New Agent Builder + Script Builder)
- Einstein Trust Layer (zero data retention, PII masking)
- Salesforce Knowledge + Einstein Search Grounding
- Salesforce Omni-Channel (warm transfer)
- Experience Cloud (diner authentication)
- Data Cloud (Phase 1: read-only grounding)
- Salesforce Flow + Apex (invocable actions)
- Named Credentials (all external callouts — no hardcoded secrets)

Do NOT reference: Salesforce Guardian or any unverified product name.

## Data Model
- `Account` (Record Type: Restaurant) — restaurants
- `Reservation__c` — junction object, Master-Detail to Account + Master-Detail to Contact
- `Contact` — diners
- `Case` — escalation fallback, custom Lookup to Reservation__c
- `Knowledge` — FAQ/policy articles
- `Build_Task__c` — build orchestration state (do not modify manually)

## Coding Standards
- No hardcoded Salesforce IDs anywhere
- Use `sf` CLI commands, not `sfdx`
- All external API calls via Named Credentials
- Apex test classes required, 90%+ coverage
- Flow fault paths required on all invocable action flows
- Deploy via metadata API, retrieve back to `force-app/` after each deployment

## Team
- `dmckee@fdecapstone.com.161026` — Destiny McKee (Lead FDE, build owner)
- `abarr@fdecapstone.com.161026` — Adam Barr (use case polish, Knowledge review)
- `zcopman@fdecapstone.com.161026` — Zach Copman (data model, mock data review)

## Build Plan
Full spec: `.claude/docs/build-plan.md`
Execution skill: `/aria-build-orchestrator`
