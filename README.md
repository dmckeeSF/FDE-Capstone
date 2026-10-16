# Aria — Intelligent Diner Support Agent
**FDE Capstone | Team 4**

Aria is an Agentforce Autonomous Service Agent (ASA) for an online hospitality and reservations platform. Diners chat with Aria to modify or cancel reservations, look up restaurant details, get policy answers, and escalate to a live agent when needed.

## Team

| Name | Salesforce Username | Role |
|---|---|---|
| Destiny McKee | dmckee@fdecapstone.com.161026 | Lead FDE — build owner |
| Adam Barr | abarr@fdecapstone.com.161026 | Use case polish, Knowledge articles |
| Zach Copman | zcopman@fdecapstone.com.161026 | Data model, mock data review |

## Demo Org

Alias: `FdeCap`

To authenticate:
```bash
sf org login web --alias FdeCap
```

Verify connection:
```bash
sf org display --target-org FdeCap --json
```

---

## Your Tasks (Zach & Adam)

You will receive a **Slack notification** when something is ready for your review. All task state lives in Salesforce — look for `Build_Task__c` records assigned to you.

**Zach** — Review AI-generated mock data (restaurants, diners, reservations) in the FdeCap org. Confirm accuracy, then update the `TASK-Z1` `Build_Task__c` record to `Status = Done`.

**Adam** — Review and fine-tune 5 AI-drafted Knowledge articles in FdeCap (Setup → Knowledge). Update `TASK-A1` to `Status = Done` when satisfied. Also review the rubric gap analysis in `.claude/docs/adam-review-draft.md` and approve before demo day.

**Both** — Sign off on automated test results in `.claude/docs/test-results.md` before the live demo.

---

## Adding Requirements

Have an idea for a new feature, field, or behavior? Post it in the team Slack channel and tag Destiny, or message Destiny directly. Include:

1. **What** — what you want Aria (or the data model) to do
2. **Why** — the use case or demo scenario it supports
3. **Priority** — must-have before demo vs. nice-to-have

Destiny will run `/aria-build-orchestrator` to validate the requirement, add it to the skill, commit and push to GitHub, then create the `Build_Task__c` record in Salesforce. You'll get a Slack notification when it's in the build.

> **Do not edit `.claude/agents/` files or `Build_Task__c` records directly** — all changes flow through the orchestrator to keep git and Salesforce in sync.

---

## Running the Build (Destiny only)

```bash
git pull
# Open Claude Code, then:
/aria-build-orchestrator
```

The skill checks your org credential, queries `Build_Task__c` for current state, asks approval before any org change, and launches sub-agents for each ready task.

---

## Repo Structure

```
force-app/          Salesforce metadata (auto-updated after each deployment)
.claude/
  agents/           Claude Code skills
    aria-build-orchestrator.md   Main execution skill
    refs/                        Lazy-loaded task specs by phase
  docs/             Build plan, test results, Adam's review draft
  build-overview.md              Full component breakdown + demo script
CLAUDE.md           Project context — auto-loaded by all Claude agents
README.md           This file
```

Full build details: `.claude/docs/build-overview.md`
