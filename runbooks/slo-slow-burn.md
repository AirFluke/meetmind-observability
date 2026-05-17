# Runbook: SLO Availability Slow Burn

## What is this alert?

**Alert:** `SLOAvailabilitySlowBurn` (warning)

The 6-hour availability burn rate exceeds 5×. At this rate, **5% of the 30-day error budget
will be consumed within 6 hours**.

This is not yet critical, but it will escalate to a fast burn if the trend continues.

## Likely cause

- Intermittent failures on a downstream dependency (database timeouts, flaky API)
- Gradual resource exhaustion (memory leak, connection pool depletion)
- Partial deployment issue affecting a subset of requests
- DNS or network instability causing sporadic probe failures

## First 3 investigation steps

1. Open the [SLO & Error Budget dashboard](http://YOUR_SERVER_IP:3000/d/slo/slo-error-budget) — check which SLI is degrading
2. Check the [Unified Observability dashboard](http://YOUR_SERVER_IP:3000/d/unified-observability) — look for error rate trends over the last 6 hours
3. Check Loki logs for error patterns: `{level=~"error|warn"} | rate()` — are errors increasing gradually?

## Resolution

- Identify the root cause from logs and traces before acting
- If intermittent dependency failure: add retry logic or circuit breaker
- If resource exhaustion: restart the affected service and investigate the leak
- If partial deployment: verify all services are running the expected version
  ```bash
  sudo bash /opt/meetmind-observability/scripts/status.sh
  ```

## Rollback criteria

Roll back if the slow burn correlates with a recent deployment (check deployment annotations
on the dashboard).

## Escalation

- Investigate within 2 hours of alert firing
- If burn rate does not decrease within 4 hours: escalate to engineering lead
- If burn rate increases to fast burn (>14.4×): follow the [SLO Fast Burn runbook](./slo-fast-burn.md)

## Error Budget Policy reference

See [error-budget-policy.md](../error-budget-policy.md) for team response at different budget levels.
