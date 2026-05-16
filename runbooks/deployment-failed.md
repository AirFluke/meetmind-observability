# Runbook: Deployment Failed

## What is this alert?

**Alert:** `CICDDeploymentFailed` — A GitHub Actions deployment workflow has failed.

## Likely cause

- Code build or test failure
- Infrastructure unreachable during deploy step
- Missing environment variables or secrets in the workflow
- Dependency resolution failure (npm, apt, pip)
- Rate limiting or quota exceeded on cloud provider

## First 3 investigation steps

1. Open GitHub Actions — find the failed run and read the error logs
2. Determine which step failed: build, test, or deploy
3. Check if the server is reachable: `curl http://YOUR_SERVER_IP:3000/api/health`

## Resolution

- If build/test failure: fix the code issue and push a new commit
- If deploy step failed but service is running: manually verify the service is still healthy
- If deploy step left a partial deployment: run `install.sh` manually to restore desired state
  ```bash
  cd /opt/meetmind-observability && sudo bash install.sh
  ```
- If missing secrets: update GitHub Actions secrets and re-run the workflow

## Rollback criteria

If the production service is degraded as a result of the failed deployment, roll back immediately
by redeploying the last known good commit.

## Escalation

If the production service is degraded: treat as an incident and follow the [SLO Fast Burn runbook](./slo-fast-burn.md).
Contact: On-call engineer immediately.
