# Runbook: High Latency

## What is this alert?

**Alert:** `HighLatencyWarning` — p95 request latency exceeds 500ms for 5+ minutes.

## Likely cause

- Downstream dependency slowness (database, external API)
- CPU or memory saturation causing processing delays
- Network congestion or packet loss
- Application-level contention (lock contention, connection pool exhaustion)

## First 3 investigation steps

1. Open the [Unified Observability dashboard](http://YOUR_SERVER_IP:3000/d/unified-observability) — check the latency panel
2. Find a slow trace in Tempo: query `{ duration > 500ms }`
3. Check CPU and memory saturation on the [Node Exporter dashboard](http://YOUR_SERVER_IP:3000/d/node-exporter) — resource exhaustion causes latency

## Resolution

- If database slow: check query plans, add indexes, restart if connection pool is exhausted
- If downstream service slow: check dependency health, consider circuit breaker
- If CPU-bound: reduce concurrency, restart the service, or scale the instance
- If network: check `tc qdisc show` for any traffic shaping rules left from testing

## Rollback criteria

Roll back if latency spike started immediately after a deployment.

## Escalation

If latency remains above SLO for 30+ minutes after investigation: escalate to engineering lead.
