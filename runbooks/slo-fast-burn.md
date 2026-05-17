# Runbook: SLO Fast Burn (Critical)

## What is this alert?
**Alert:** `SLOAvailabilityFastBurn`
The error budget is burning at 14.4× or more — meaning 2% of the 30-day error budget
will be consumed in the next hour if the situation continues.

At 14.4× burn rate you have approximately **1 hour** to act before significant budget damage.

## Likely cause
1. Recent deployment introduced a regression causing HTTP 5xx responses
2. Dependency (database, external API) is down or degraded
3. Server resource exhaustion causing request timeouts
4. Misconfiguration causing probe failures

## First 3 investigation steps

1. **Open the SLO dashboard immediately:**
   [SLO & Error Budget](http://13.63.206.183:3000/d/slo-error-budget)
   Note the burn rate trend — is it accelerating or stabilising?

2. **Open the Unified Observability dashboard:**
   [Unified Observability](http://13.63.206.183:3000/d/unified-observability)
   Check the error rate panel for the time the burn started.
   Click "See correlated logs in Loki" to find error messages from that window.
   Follow the trace ID link to Tempo to find the causing trace.

3. **Check recent deployments:**
   ```bash
   # On the server:
   docker compose logs --tail=100 --since="30m ago"
   # On GitHub: check Actions tab for recent workflow runs
   ```

## Resolution

- If a deployment caused it: **roll back immediately** (don't investigate in prod under burn)
  ```bash
  cd /opt/meetmind-observability
  # Edit docker-compose.yml to pin previous image tag, then:
  docker compose up -d
  ```
- If a dependency is down: implement circuit breaker / return cached response
- If resource exhaustion: scale up, kill runaway processes

## Escalation
If not resolved within 30 minutes: escalate to engineering lead.
If budget reaches 0%: feature freeze per [Error Budget Policy](../error-budget-policy.md).

---

# Runbook: SLO Slow Burn (Warning)

## What is this alert?
**Alert:** `SLOAvailabilitySlowBurn`
The error budget is burning at 5× or more over a 6-hour window — 5% will be consumed
in 6 hours. You have time to investigate but must act before it escalates.

## First 3 investigation steps

1. Open [SLO & Error Budget](http://13.63.206.183:3000/d/slo-error-budget) and
   check how long the slow burn has been active.

2. Check error rate trend on the [Unified Observability](http://13.63.206.183:3000/d/unified-observability)
   dashboard — is it steady or increasing?

3. Review last 6 hours of logs in Loki:
   Query: `{level="error"} | logfmt | __error__=""` 

## Resolution
Same steps as Fast Burn but with more time. Prioritise finding root cause
before the burn rate increases to fast-burn territory.

## Escalation
If no improvement after 2 hours: escalate to on-call lead.
