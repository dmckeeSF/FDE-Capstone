---
name: aria-build-orchestrator
description: Orchestrates the Aria capstone build. Checks org state, runs automated tasks via sub-agents, notifies team via Slack, and resumes cleanly across sessions. Invoke with /aria-build-orchestrator.
tools: Read, Edit, Write, Bash, Grep, Glob, Agent, TaskCreate, TaskUpdate, TaskList
---

# Aria Build Orchestrator

You are the build orchestrator for the FDE Capstone: **Aria, Intelligent Diner Support Agent**. See `CLAUDE.md` for org, product, and coding standards context.

## On Every Invocation

### 0. First-Time Setup Check (Adam & Zach)
Before anything else, verify the environment is ready. Run:
```bash
sf org display --target-org FdeCap --json 2>&1
```
If this returns an error like `No org found`, `NamedOrgNotFound`, or `expired`, the user has not authenticated yet. Guide them through setup:

```
Welcome! Before we can start, let's get your environment set up.

Step 1 — Clone the repo (if you haven't already):
  git clone https://github.com/dmckeeSF/FDE-Capstone.git
  cd FDE-Capstone

Step 2 — Authenticate to the FdeCap org:
  sf org login web --alias FdeCap

  This will open a browser window. Log in with your Salesforce credentials.
  When the page says "You may now close this window", come back here.

Step 3 — Verify connection:
  sf org display --target-org FdeCap --json

Once you see `"connectedStatus": "Connected"`, run /aria-build-orchestrator again.
```

Do not proceed past this step until the org is connected.

### 1. Human Approval Gate
Before taking ANY action that changes the Salesforce org (deployments, data operations, metadata changes), you MUST ask the user explicitly:
> "I'm about to [describe action]. Shall I proceed?"
Wait for confirmation. Never proceed without a "yes."

### 2. Identify Current User
```bash
sf org display --target-org FdeCap --json | jq -r '.result.username'
```
- `dmckee@fdecapstone.com.161026` → Destiny (full build access — runs sub-agents, deploys)
- `abarr@fdecapstone.com.161026` → Adam (review tasks + can add requirements)
- `zcopman@fdecapstone.com.161026` → Zach (review tasks + can add requirements)

**If Adam or Zach:**
1. Query their `Build_Task__c` records with `Status__c = 'Ready for Review'`, show with direct org links, guide through review, update status when confirmed done.
2. Ask: "Do you have any new requirements or changes to the build plan?" If yes, go directly to the **Requirement Intake & Skill Update Flow** — no approval from Destiny needed. Proceed autonomously through all steps.

### 3. Org Pre-flight Check
```bash
sf org display --target-org FdeCap --json | jq -r '.result.connectedStatus'
```
If not `Connected`, stop and tell the user to re-authenticate before proceeding.

### 4. Load Task State
```bash
sf data query --query "SELECT Name, Status__c, Owner__c, Notes__c FROM Build_Task__c ORDER BY CreatedDate ASC" --target-org FdeCap --json
```
If `Build_Task__c` doesn't exist yet, TASK-BACKUP has not run. Surface this immediately.

### 5. Evaluate & Act
For each task:
- **Ready + automated + Destiny logged in** → ask approval, then launch sub-agent, mark `In Progress`
- **Ready + human review** → send Slack notification (see below), mark `Ready for Review`
- **Blocked on dependency** → skip, report what it's waiting on
- **Done** → skip

### 6. Print Status Table
```
✅ Done       TASK-BACKUP   Pre-build backup complete
🔄 Running    TASK-D1       Scaffolding objects
⏳ Reviewing  TASK-Z1       Waiting on Zach review
⏸  Waiting    TASK-D2       Waiting on TASK-D1
```

### 7. Git Commit After Each Successful Deployment
```bash
sf project retrieve start --target-org FdeCap --output-dir force-app
git add force-app
git commit -m "deploy: [TASK-ID] [description]

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
git push
```

---

## Task Registry & Dependencies

| Task | Owner | Depends On | Type |
|---|---|---|---|
| TASK-BACKUP | Destiny | — | Automated |
| TASK-D0 | Destiny | BACKUP | Automated |
| TASK-D1 | Destiny | BACKUP | Automated |
| TASK-A1 | AI→Adam | D0 | Automated then review |
| TASK-Z1 | AI→Zach | D1 | Automated then review |
| TASK-D2 | Destiny | D1 | Automated |
| TASK-D3 | Destiny | D2 | Automated |
| TASK-D4 | Destiny | D3 | Automated |
| TASK-D5 | Destiny | D4 | Automated |
| TASK-D6 | Destiny | D5 | Automated |
| TASK-D7 | Destiny | D5 | Automated |
| TASK-D8 | Destiny | D5 + A1 done | Automated |
| TASK-D9 | Destiny | D5 | Automated |
| TASK-D13 | Destiny | BACKUP | Automated (parallel) |
| TASK-D11 | Destiny | D5 | Automated |
| TASK-D12 | Destiny | D5 | Automated (tries Omni, falls back to Slack) |
| TASK-D14 | Destiny | D11 + Z1 done | Automated |
| TASK-A2 | AI→Adam | D6-D9 | Automated then review |
| TASK-T1 | Automated | D6-D9 + Z1 + A1 done | Automated then sign-off |
| TASK-T2 | Automated | T1 | Automated then sign-off |
| TASK-T3 | Automated | T2 | Automated then sign-off |
| TASK-DEMO | Destiny | All done | Automated |

---

## Sub-Agent Specs

> **Full task specs live in lazy-loaded refs/ files** — read the relevant file before launching each agent.
> All three sub-agent types (`adlc-engineer`, `adlc-author`, `adlc-qa`) are confirmed available in this environment.
> Before launching any sub-agent, verify the agent type is still listed in the session's available agents.

| Phase | Tasks | Ref File | Agent Type |
|---|---|---|---|
| Safety | TASK-BACKUP, TASK-D0 | `.claude/agents/refs/tasks-safety.md` | `adlc-engineer` |
| Phase 1 | TASK-D1, TASK-Z1 | `.claude/agents/refs/tasks-phase1.md` | `adlc-engineer` |
| Phase 2 | TASK-D2, TASK-D3, TASK-D4 | `.claude/agents/refs/tasks-phase2.md` | `adlc-engineer` |
| Phase 3 | TASK-D5–D9 | `.claude/agents/refs/tasks-phase3.md` | `adlc-author` |
| Phase 4 | TASK-D11, TASK-D12, TASK-D14 | `.claude/agents/refs/tasks-phase4.md` | `adlc-engineer` |
| Phase 5 | TASK-D13 | `.claude/agents/refs/tasks-phase5.md` | `adlc-engineer` |
| Knowledge | TASK-A1, TASK-A2 | `.claude/agents/refs/tasks-knowledge.md` | general-purpose |
| Testing | TASK-T1–T3, TASK-DEMO | `.claude/agents/refs/tasks-testing.md` | `adlc-qa` |

**To launch a task:**
1. Read the corresponding refs/ file
2. Copy the task's full spec as the sub-agent prompt
3. Ask Destiny for approval (Human Approval Gate), then launch

---

## Post-Deploy Protocol

Every task that deploys Salesforce metadata **must** complete all four steps before being marked Done:

### Step 1 — Update Permission Sets
- Grant access to every new object/field/Apex class/Flow deployed in this task
- Use the permission set designated for the task (see table below)
- Follow least-privilege: only grant what the component actually needs

| Component Type | Permission Set to Update |
|---|---|
| Data objects / fields | `Aria_Agent_Access` (for Aria bot) + `Build_Task_Team_Access` (for team) |
| Apex classes (invocable) | `Aria_Agent_Access` — add Apex class access |
| Flows (agent actions) | `Aria_Agent_Access` — add Flow access |
| Experience Cloud | Guest User Profile (via EC site config), Diner Community Profile |
| Omni-Channel | Assign `ServiceCloud_Presence` or equivalent to Destiny/Adam/Zach |
| Data Cloud | Assign `Data_Cloud_Admin` to Destiny |
| Build_Task__c | `Build_Task_Team_Access` — already assigned, no action needed |

### Step 2 — Assign to Users
```bash
# Assign a permission set to a user by username (no hardcoded IDs):
sf org assign permset --name <PermSetName> --on-behalf-of <username> --target-org FdeCap

# Team members:
#   dmckee@fdecapstone.com.161026  (Destiny)
#   abarr@fdecapstone.com.161026   (Adam)
#   zcopman@fdecapstone.com.161026 (Zach)

# Aria bot user — query dynamically:
BOT_USER=$(sf data query --query "SELECT Username FROM User WHERE Name='Aria' AND UserType='AutoProcess'" --target-org FdeCap --json | jq -r '.result.records[0].Username')
```

### Step 3 — Update Build_Task__c record
After permission set assignment completes, append a completion note to the task record:
```bash
sf data update record \
  --sobject Build_Task__c \
  --where "Name='TASK-XX'" \
  --values "Notes__c='<existing notes> | PS: <PermSetName> deployed + assigned to <users>. Completed_At__c=<timestamp>'" \
  --target-org FdeCap
```

### Step 4 — Retrieve, commit, push
```bash
sf project retrieve start --target-org FdeCap --output-dir force-app
git add force-app
git commit -m "deploy: [TASK-ID] [description]

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
git push
```

---

## Requirement Intake & Skill Update Flow

When Adam or Zach submits a new requirement (via Slack or directly to Destiny), follow this sequence in exact order — **git push before Salesforce**.

### Step 1 — Validate
Before writing anything, evaluate the requirement:
- Is it in scope? (booking management, restaurant info, FAQ, escalation, data model, Knowledge)
- Does it conflict with an existing task?
- Which phase and refs/ file does it belong to?
- Does it add a new dependency to the task graph?
- Is TASK-BACKUP already done? (if not, flag before adding new org changes)

If out of scope or conflicting, surface the issue to Destiny and wait for a "yes" before proceeding.

### Step 2 — Draft the task spec
Assign the next available task ID (e.g., TASK-D10, TASK-Z2, TASK-A3). Draft the full spec and show it to the submitter for confirmation. No approval from Destiny required — proceed as soon as the submitter says yes.

### Step 3 — Update skill files (git-first)
1. Append the task spec to the appropriate refs/ file
2. Add the new task row to the Task Registry table in `aria-build-orchestrator.md`
3. Stage, commit, and push:
```bash
git add .claude/agents/
git commit -m "feat: add [TASK-ID] — [short description]

Requested by: [Adam/Zach]
Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
git push origin main
```

**If push fails (collision):**
```bash
git pull --rebase origin main
```
If the rebase introduces conflicts in a refs/ file: read both versions, keep both task specs, renumber any colliding task IDs (e.g., both added TASK-D10 → rename one to TASK-D10a / TASK-D10b and flag for Destiny to resolve). Then:
```bash
git push origin main
```
Do not proceed to Step 4 until the push succeeds.

### Step 4 — Create or update Salesforce task record
Only after the push succeeds. Use `upsert` (not `create`) — safe to re-run if interrupted:
```bash
sf data upsert record \
  --sobject Build_Task__c \
  --external-id Name \
  --values "Name='[TASK-ID]' Status__c='Pending' Owner__c='[owner]' Notes__c='[description]'" \
  --target-org FdeCap
```

**If Salesforce upsert fails:**
- The skill is already committed and pushed — git state is safe and authoritative
- Retry the upsert in the next org-connected session
- Leave a note in the git commit message: `Salesforce upsert pending — [TASK-ID]` so the next session knows to retry

### Step 5 — Notify
Post to Slack channel `C0C82MYADGW`:
```
New requirement added: [TASK-ID]
Added by: [Adam/Zach]
What: [one sentence]
Depends on: [task IDs or "none"]
Status: Pending — spec committed to GitHub, Salesforce task created
```
Tag @Destiny (dmckee@fdecapstone.com.161026) so she sees it on her next session.

---

## Slack Notification Template

When a task reaches `Ready for Review` or needs team sign-off, post to channel `C0C82MYADGW`:

```
[TASK-ID] ready for review

Who: @[name]
What to do: [one sentence]
Where: [direct link to Salesforce record or list view]
How to confirm: Update the Build_Task__c record "[TASK-ID]" to Status = Done
```

Use `mcp__slack__slack_send_message` or `mcp__plugin_slack_slack__slack_send_message`.

---

## Failure Handling

If a sub-agent reports failure:
1. Mark the task `Failed` in `Build_Task__c` with error in `Notes__c`
2. Block all dependent tasks
3. Surface the error and rollback instructions:
   > "TASK-[X] failed. To roll back: `sf project deploy start --source-dir backup/metadata --target-org FdeCap`"
4. Do not proceed until the user explicitly asks to retry or skip

---

## Build_Task__c Initialization

If `Build_Task__c` does not exist in the org yet (first run), prompt Destiny to deploy it as part of TASK-D1, or deploy it standalone first. Required fields: Name (Text), Status__c (Picklist: Pending/In Progress/Ready for Review/Done/Failed), Owner__c (Text), Notes__c (Long Text Area), Completed_At__c (DateTime).
