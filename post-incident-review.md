# Blameless Post-Incident Review

**Incident ID:** INC-001
**Date:** 2025-05-17
**Severity:** SEV-2 (service degraded, not fully down)
**Author:** DevOps Team
**Status:** Resolved

---

## Summary

A deployment of a new feature pushed an application config change that caused 35% of HTTP requests
to return 503 for approximately 47 minutes. The SLO fast-burn alert fired 6 minutes into the
incident. Recovery was achieved by rolling back the deployment.

---

## Impact

- **Duration:** 47 minutes (14:23 – 15:10 UTC)
- **Error budget consumed:** ~5.5% of monthly availability budget
- **Users affected:** Estimated 40% of active sessions during the window
- **Requests failed:** ~12,000 requests returned 503

---

## Timeline

| Time (UTC) | Event |
|------------|-------|
| 14:18 | Deployment workflow triggered on merge to main |
| 14:23 | Deployment completes; new container version running |
| 14:23 | First 503 responses observed (app misconfiguration) |
| 14:29 | `SLOAvailabilityFastBurn` fires in #DevOps-Alerts (6-min detection lag) |
| 14:31 | On-call engineer acknowledges alert |
| 14:34 | Engineer opens Unified Observability dashboard, sees error rate spike |
| 14:36 | Clicks trace ID in Loki logs → Tempo trace shows config read failure |
| 14:40 | Root cause identified: missing env var `DATABASE_URL` in new deployment |
| 14:45 | Rollback initiated: `docker compose up -d` with previous image |
| 15:10 | Error rate returns to baseline; `SLOAvailabilityFastBurn` resolves |
| 15:12 | Post-incident Slack thread opened |

---

## Root Cause

A new environment variable (`DATABASE_URL`) was added to the application code but not added
to the `docker-compose.yml` environment block. The application started successfully but failed
at request-handling time when it tried to read the variable.

---

## What Went Wrong in Detection

1. **6-minute detection lag:** The `for: 2m` clause on the fast-burn alert requires 2 minutes
   of sustained burn before firing. Combined with Prometheus scrape interval, detection took ~6 minutes.

2. **No deploy-time smoke test:** The deployment workflow had no post-deploy health check.
   A single `curl` to the health endpoint would have caught this in under 60 seconds.

---

## What Went Well

1. The Loki → Tempo drill-down reduced time-to-diagnosis from hours to 4 minutes.
2. The alert payload included a direct link to the dashboard — no searching required.
3. The team had a runbook for deployment failures that was followed correctly.

---

## Action Items

| Action | Owner | Due date |
|--------|-------|----------|
| Add post-deploy smoke test to GitHub Actions workflow | DevOps | 2025-05-20 |
| Add env var validation to Docker entrypoint script | App dev | 2025-05-22 |
| Reduce `for:` clause on fast-burn alert from 2m to 1m | DevOps | 2025-05-19 |
| Add deployment config diff check to PR template | DevOps | 2025-05-24 |

---

## Contributing Factors (not blame)

- The PR template did not prompt reviewers to check environment variable additions.
- There is no automated diff between `docker-compose.yml` env block and application env var usage.

---

*This review is blameless. We focus on systems and processes, not individuals.*
