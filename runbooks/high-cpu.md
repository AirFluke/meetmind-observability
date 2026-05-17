# Runbook: High CPU Usage

## What is this alert?
**Alert:** `HighCPUWarning` / `HighCPUCritical`
CPU utilisation has exceeded 80% (warning) or 90% (critical) on an instance.

## Likely cause
1. Traffic spike — more requests than usual hitting the service
2. Runaway process — a single process consuming excessive CPU
3. Background job contention — batch jobs running during peak hours
4. Memory pressure causing excessive GC or swap activity
5. Post-deployment regression — new code is computationally expensive

## First 3 investigation steps

1. **Check running processes:**
   ```bash
   ssh ubuntu@13.63.206.183
   top -bn1 | head -20
   # Or: ps aux --sort=-%cpu | head -10
   ```

2. **Correlate with traffic:**
   Open the [Unified Observability dashboard](http://13.63.206.183:3000/d/unified-observability)
   and check if the traffic panel shows a spike matching the CPU spike window.

3. **Check for runaway containers:**
   ```bash
   docker stats --no-stream
   ```

## Resolution

- If a runaway process: `kill -9 <PID>` and investigate root cause
- If traffic-driven: scale horizontally (add instances) or rate-limit upstream
- If a deployment regression: roll back (`docker compose up -d` with previous image tag)
- If GC pressure: check memory usage; may need to increase container memory limits

## Rollback criteria
Roll back the most recent deployment if:
- CPU spike started within 30 minutes of a deployment
- The spike correlates with increased error rate
- No other external cause is identified

## Escalation
Escalate to senior engineer if:
- CPU remains > 90% for more than 30 minutes after initial investigation
- Root cause is unknown after 20 minutes
- Multiple instances are affected simultaneously
