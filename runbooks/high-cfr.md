# Runbook: High Change Failure Rate

## What is this alert?

**Alert:** `CICDHighChangeFailureRate` — Change Failure Rate exceeds 15% over a rolling 7-day window.

DORA classification at this level: **Low performer**.

## Likely cause

- Insufficient test coverage — broken code reaching production
- Missing pre-deploy health checks or smoke tests
- Environment configuration drift between staging and production
- Rushed deployments without proper review

## First 3 investigation steps

1. Open the [DORA Metrics dashboard](http://YOUR_SERVER_IP:3000/d/dora/dora-metrics) — identify which workflows are failing
2. Check GitHub Actions for failed workflow runs in the last 7 days
3. Check if failures cluster around specific times, branches, or contributors

## Resolution

- Add required status checks to block merging of failing PRs
- Improve test coverage for the failing deployment paths
- Add a post-deploy smoke test step to the GitHub Actions workflow
- Consider adding canary deployments before full rollout

## Rollback criteria

Not applicable — this is a trend metric, not a single-incident alert.

## Escalation

If CFR stays above 15% for 2+ consecutive weeks: conduct a deployment process review with the full team.
Contact: Engineering manager.
