# Runbook: High Memory Usage

## What is this alert?
**Alert:** `HighMemoryWarning` / `HighMemoryCritical`
Memory utilisation has exceeded 80% (warning) or 90% (critical).

## First 3 investigation steps
1. Identify the memory consumer: `docker stats --no-stream`
2. Check for memory leaks: `docker compose logs <service> | grep -i "oom\|memory\|heap"`
3. Check if swap is in use: `free -h && swapon --show`

## Resolution
- Restart the leaking container: `docker compose restart <service>`
- Increase memory limit in docker-compose.yml if legitimate usage
- If OOM kills are occurring, add swap: `sudo fallocate -l 2G /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile`

## Rollback criteria
Roll back if memory spike started within 30 minutes of a deployment.

## Escalation
Escalate if memory stays > 90% after restart, or if the server becomes unresponsive.

---

# Runbook: Disk Space

## What is this alert?
**Alert:** `DiskSpaceWarning` (75%) / `DiskSpaceCritical` (90%)

## First 3 investigation steps
1. Find the large directories: `du -sh /* 2>/dev/null | sort -rh | head -20`
2. Check Docker volumes: `docker system df`
3. Check Prometheus/Loki data sizes: `du -sh /var/lib/docker/volumes/`

## Resolution
- Clean Docker resources: `docker system prune -af --volumes` (CAUTION: removes unused volumes)
- Reduce retention: edit `--storage.tsdb.retention.time` in docker-compose.yml for Prometheus
- Clear old logs: `journalctl --vacuum-size=500M`

## Escalation
If disk is > 95% and cannot be freed: escalate immediately — filesystem full = service down.

---

# Runbook: High Latency

## What is this alert?
**Alert:** `HighLatencyWarning` — p95 > 500ms

## First 3 investigation steps
1. Open [Unified Observability](http://YOUR_SERVER_IP:3000/d/unified-observability) — latency panel
2. Find a slow trace in Tempo: query `{ duration > 500ms }`
3. Check CPU and memory saturation — resource exhaustion causes latency

## Resolution
- If database slow: check query plans, add indexes
- If downstream slow: check dependency health
- If CPU-bound: reduce concurrency or scale

---

# Runbook: High Change Failure Rate

## What is this alert?
**Alert:** `CICDHighChangeFailureRate` — CFR > 15% over 7 days

## First 3 investigation steps
1. Open [DORA Metrics](http://YOUR_SERVER_IP:3000/d/dora-metrics) — identify which workflows are failing
2. Check GitHub Actions for failed workflow runs in the last 7 days
3. Check if failures cluster around specific times, branches, or team members

## Resolution
- Add required status checks to block merging of failing PRs
- Improve test coverage for the failing deployment paths
- Consider adding canary deployments before full rollout

---

# Runbook: High MTTR

## What is this alert?
**Alert:** `CICDHighMTTR` — 7-day average MTTR > 1 hour

## First 3 investigation steps
1. Review recent incidents: were runbooks followed? Were they accurate?
2. Check if alerts fired early enough (detection lag adds to MTTR)
3. Identify manual steps in the resolution process that can be automated

## Resolution
- Update runbooks for any incident where the runbook was missing or wrong
- Add automation for repetitive resolution steps (restart scripts, rollback automation)
- Improve alert sensitivity if detection was late

## Escalation
If MTTR remains high for 2+ weeks: conduct a process review with the full team.

---

# Runbook: SSL Certificate Expiry

## What is this alert?
**Alert:** `SSLCertExpiringSoon` — certificate expires in < 14 days

## First 3 investigation steps
1. Confirm the certificate details: `openssl s_client -connect <host>:443 | openssl x509 -noout -dates`
2. Check if certbot is installed and the renewal cron is running: `sudo certbot renew --dry-run`
3. Check DNS is pointing to the correct server

## Resolution
- Renew immediately: `sudo certbot renew`
- Restart web server after renewal: `sudo systemctl reload nginx`

## Escalation
If auto-renewal fails: escalate to senior engineer — expired SSL = service unavailable for HTTPS users.

---

# Runbook: Deployment Failed

## What is this alert?
**Alert:** `CICDDeploymentFailed`

## First 3 investigation steps
1. Open GitHub Actions — find the failed run and read the error logs
2. Check if the failure is in build, test, or deploy step
3. Check if the server is reachable: `curl http://YOUR_SERVER_IP:3000/api/health`

## Resolution
- Fix the code issue and push a new commit
- If deploy step failed with a running service: manually verify the service is still up
- If deploy step left a partial deployment: `docker compose up -d` to restore desired state

## Escalation
If the production service is degraded as a result: treat as an incident and follow the SLO Fast Burn runbook.
