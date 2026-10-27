# Aria — Build Summary
## Tools, Testing, Repository Management & Quality Checks

---

## Tools

| Layer | Tool | Purpose |
|---|---|---|
| CLI | `sf` (Salesforce CLI) | All org operations — deploy, retrieve, validate, publish, test |
| Agent authoring | Agent Script (`.agent` files) | Defines Aria's subagent graph, routing logic, and action bindings |
| Actions | Apex `@InvocableMethod` | Custom business logic: reservation lookup, location search, case summary, escalation |
| Routing | Autolaunched Flows + RoutingFlow | Wrap Apex actions for agent invocation; `ServiceAgentEscalationFlow` drives warm transfer |
| Knowledge | Salesforce Knowledge + Einstein Search Grounding | FAQ and restaurant guide articles grounded into agent reasoning automatically |
| Security | Einstein Trust Layer | Zero data retention, PII masking, toxicity detection — platform-enforced |
| Credentials | Named Credentials | All external callouts — no secrets in code |
| Channel | Experience Cloud + Omni-Channel | Diner-facing chat surface; human agent queue for warm transfer |
| Grounding | Data Cloud (Phase 1, read-only) | Unified diner profile context surfaced as grounding input |
| State | `Build_Task__c` custom object | Shared build task state across team sessions — no local state files |

---

## Testing

**Mode A — Ad-Hoc Preview (development iteration)**

```bash
sf agent preview start --json --authoring-bundle Aria --target-org FdeCap
sf agent preview send --json --session-id <ID> --authoring-bundle Aria --utterance "..." --target-org FdeCap
sf agent preview end --json --session-id <ID> --authoring-bundle Aria --target-org FdeCap
```

Traces written to `.sfdx/agents/Aria/sessions/{sessionId}/traces/{planId}.json`. Used to verify subagent routing, action invocation (`FunctionStep` presence), and variable updates after every change.

**Mode B — Testing Center Batch (regression suite)**

Test specs live in `tests/`:
- `Aria-testing-center.yaml` — full smoke suite (routing, actions, guardrails, safety)
- `Aria-restaurant-info-conversation.yaml` — multi-turn restaurant discovery flow

```bash
sf agent test create --json --spec tests/Aria-testing-center.yaml --api-name AriaSmokeTests --target-org FdeCap
sf agent test run --json --api-name AriaSmokeTests --wait 10 --result-format json --target-org FdeCap
```

**Action Execution — Isolated action testing**

Apex and Flow actions tested directly via REST before wiring into the agent:

```bash
curl "$INSTANCE/services/data/v63.0/actions/custom/apex/<ClassName>" \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"inputs": [{"param": "value"}]}'
```

**Test categories covered:** subagent routing, action invocation, grounding accuracy, authentication gating, cancellation policy boundary, multi-turn context, adversarial/safety probes.

---

## Repository Management

**Structure:**

```
force-app/main/default/
  aiAuthoringBundles/Aria/     # Agent Script source
  classes/                     # Apex actions + test classes
  flows/                       # Invocable action flows + escalation routing flow
  knowledge/                   # Knowledge article metadata
  permissionsets/              # Least-privilege permission sets
  genAiPromptTemplates/        # Prompt templates (Escalation Case Summary)
tests/                         # Testing Center YAML specs + CSV datasets
.claude/docs/                  # Build plan, technical considerations, this summary
CLAUDE.md                      # Project context auto-loaded by every agent session
```

**Retrieve-after-deploy rule:** every deployment is followed by a `sf project retrieve start` to keep `force-app/` in sync with the org. The agent bundle's `bundle-meta.xml` target version is updated on each retrieve.

**Commit cadence:** metadata committed to `main` after each completed task. Commit messages include what changed and why.

**No hardcoded IDs:** all org references use dynamic SOQL (`WHERE DeveloperName = '...'`, `WHERE RecordType.Name = '...'`). The pre-commit hook flags hardcoded 15/18-character Salesforce IDs.

---

## Quality Checks

| Check | Threshold | How enforced |
|---|---|---|
| Apex test coverage | 90%+ per class | `sf apex run test --code-coverage` before every deploy |
| Agent script compilation | Zero errors | `sf agent validate authoring-bundle` before every deploy |
| Flow fault paths | Required on all invocable flows | Code review gate — no flow deployed without fault connector on every action node |
| No dynamic SOQL | All queries use bind variables | Code standard; reviewed on every Apex class |
| No hardcoded IDs | Zero tolerance | Pre-commit hook + CLAUDE.md rule |
| `with sharing` on all Apex | Required | Class-level declaration on every `@InvocableMethod` class |
| Action trace verification | After every agent change | `FunctionStep` confirmed in preview trace before marking a fix complete |
| Safety probe pass | SAFE verdict required | Adversarial utterances in test suite; any UNSAFE finding blocks deployment |
