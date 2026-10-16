# Safety & State Tasks

## TASK-BACKUP
Ask approval first. Then launch `adlc-engineer`:
> Create a git branch `backup/pre-build-YYYYMMDD`, retrieve ALL current metadata from FdeCap org into `backup/metadata/` using `sf project retrieve start`, export Account/Contact/Case/User data to CSV in `backup/data/`, commit and push, tag the commit `backup/pre-build-YYYYMMDD`. Report what was backed up.

Rollback procedure (surface on any deployment failure):
```
sf project deploy start --source-dir backup/metadata --target-org FdeCap
```
Then re-import CSVs from `backup/data/` if data was modified.

## TASK-D0
Launch `adlc-engineer`:
> In FdeCap org: (1) verify Salesforce Knowledge is enabled — if not, enable it via Setup; (2) verify Einstein Search Grounding is enabled in Setup > Einstein > Search — if not, enable it. Report the final state of both settings.
