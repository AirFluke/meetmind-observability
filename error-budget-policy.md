# Error Budget Policy — MeetMind Platform

## Purpose

This policy governs how the team responds to error budget consumption. It converts
SLO targets into concrete team behaviours and escalation triggers.

## Error Budgets

| SLO | Target | Window | Budget |
|-----|--------|--------|--------|
| Availability | 99.5% | 30 days | 216 minutes |
| Error rate | 99% success | 30 days | 432 minutes |
| Latency | p95 < 500ms | rolling 5m | N/A (alert-only) |

## Policy Triggers

### Budget > 50% remaining — normal operations
- Deploy at will
- Feature work continues
- Review SLO health in weekly sync

### Budget 25–50% remaining — caution
- Notify on-call lead in weekly sync
- Begin root-cause investigation for recent incidents
- No major architectural changes to affected services

### Budget < 25% remaining — reliability sprint
- On-call lead files a reliability sprint ticket
- At least one sprint item must address reliability before new features
- Senior engineer reviews all deployments to affected services
- Daily budget check-in in Slack

### Budget exhausted (0%) — feature freeze
- **Feature freeze on affected service** — no new features until budget recovers
- Engineering manager notified immediately
- Post-incident review (PIR) required within 48 hours
- Reliability sprint becomes the team's top priority
- SLO target may be revisited in the next review cycle

## Burn Rate Thresholds

| Alert | Burn Rate | Meaning | Response |
|-------|-----------|---------|----------|
| Fast Burn (critical) | > 14.4× | 2% budget in 1h | Page on-call immediately |
| Slow Burn (warning) | > 5× | 5% budget in 6h | Investigate within 2h |

## Decision Authority

- **Who calls feature freeze?** Engineering lead (or on-call if unreachable)
- **Who approves a freeze lift?** Engineering manager + on-call lead jointly
- **Who revises SLO targets?** Engineering manager, after monthly SLO review

## SLO Review Cadence

SLOs are reviewed on the first Monday of each month. The review covers:
1. Actual availability vs target (30-day rolling)
2. Error budget consumed this month
3. DORA benchmark classification
4. Whether SLO targets are still appropriate (not too loose, not aspirationally tight)

## Toil Identified

| Toil | Current state | Proposed automation |
|------|--------------|---------------------|
| Manual Slack alert acknowledgement | Engineer reads alert, manually opens Grafana | Alert links open directly to filtered dashboard |
| Certificate renewal | Manual reminder + renewal | Let's Encrypt auto-renewal via certbot + SSL expiry alert |
| Deployment metric annotation | Manual comment in Grafana | GitHub Actions auto-annotates via Grafana API |
| Log level changes for debugging | SSH to server, edit config, restart | Log level endpoint via OTel collector hot reload |
