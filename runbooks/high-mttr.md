# Runbook: High Mean Time to Restore (MTTR)

## What is this alert?

**Alert:** `CICDHighMTTR` — 7-day average MTTR exceeds 1 hour.

DORA classification at this level: **Low performer** (Elite < 1h).

## Likely cause

- Runbooks are missing, outdated, or unclear — engineers spend time figuring out what to do
- Alerts fired too late (high detection lag adds to MTTR)
- Manual resolution steps that could be automated
- Lack of observability — engineers can't quickly pinpoint the root cause
- Escalation delays — unclear ownership of services

## First 3 investigation steps

1. Review recent incidents: were runbooks followed? Were they accurate?
2. Check if alerts fired early enough — compare alert firing time vs. actual incident start
3. Identify manual steps in the resolution process that could be automated

## Resolution

- Update runbooks for any incident where the runbook was missing or wrong
- Add automation for repetitive resolution steps (restart scripts, rollback automation)
- Improve alert sensitivity if detection was late (reduce `for:` duration on critical alerts)
- Ensure Loki → Tempo correlation is working so root cause analysis is faster

## Rollback criteria

Not applicable — this is a trend metric.

## Escalation

If MTTR remains high for 2+ weeks: conduct a process review with the full team.
Contact: Engineering manager.
