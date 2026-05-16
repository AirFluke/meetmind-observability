# Game Day — Chaos & Failure Simulation

Run all three scenarios on Sunday before your Monday presentation.
Screenshot every step: trigger → degradation → alert in Slack → trace in Tempo → recovery.

---

## Scenario 1: Deployment Failure

**Goal:** Trigger a failing GitHub Actions deployment. Observe DORA CFR alert fires in Slack.

### Steps

1. Create a deliberately failing workflow step:
   ```yaml
   # Temporarily add to .github/workflows/deploy.yml:
   - name: Intentional failure (Game Day)
     run: exit 1
   ```

2. Push to main and watch the workflow fail.

3. The workflow's failure handler pushes `deployment_total{status="failure"}` to Pushgateway.

4. Within ~5 minutes, `CICDDeploymentFailed` alert fires in #DevOps-Alerts.

5. Screenshot: GitHub Actions failure page, Pushgateway metrics page, Slack alert payload.

6. Check the DORA dashboard — CFR should increase. Screenshot the `dora-metrics` dashboard.

7. Revert the failing step and push again to record a successful deployment.

---

## Scenario 2: Latency Injection

**Goal:** Simulate high latency, observe SLO burn rate increase, fast burn alert fire,
and trace the slow request in Tempo.

### Steps

1. SSH to the server and inject network latency:
   ```bash
   ssh ubuntu@YOUR_SERVER_IP
   sudo tc qdisc add dev eth0 root netem delay 600ms 100ms
   ```
   This adds 600ms ± 100ms latency to all outgoing traffic.

2. Watch the Unified Observability dashboard — the p95 latency panel should
   climb above 500ms within the next scrape cycle (15s).

3. The `HighLatencyWarning` alert fires after 5 minutes sustained above 500ms.

4. Navigate to the Loki logs panel — find log entries from the latency window.
   Click the trace ID link → Tempo opens the slow span.

5. Screenshot each step: latency spike on dashboard, alert in Slack, Loki logs with
   trace ID link, Tempo waterfall showing the 600ms span.

6. Remove the latency injection:
   ```bash
   sudo tc qdisc del dev eth0 root netem
   ```

7. Screenshot the recovery alert in Slack.

---

## Scenario 3: Resource Pressure

**Goal:** Simulate CPU/memory pressure, confirm alerts fire warning before critical,
confirm recovery alert sends when pressure clears.

### Steps

1. Install stress tools:
   ```bash
   sudo apt-get install -y stress-ng
   ```

2. Apply CPU pressure (warning level first):
   ```bash
   stress-ng --cpu 2 --timeout 360s &
   ```
   Wait ~5 minutes → `HighCPUWarning` fires (CPU > 80% for 5m).

3. Increase to critical:
   ```bash
   stress-ng --cpu $(nproc) --timeout 600s &
   ```
   Wait ~10 minutes → `HighCPUCritical` fires (CPU > 90% for 10m).
   Verify inhibition: `HighCPUWarning` is **suppressed** (critical inhibits warning).

4. Screenshot: warning Slack message, then critical Slack message.
   Confirm on Node Exporter dashboard that the CPU panel shows the expected spike.

5. Kill the stress process:
   ```bash
   pkill stress-ng
   ```

6. Wait ~5 minutes → both CPU alerts resolve with "RESOLVED" messages in Slack.
   Screenshot the resolved notifications.

7. Repeat with memory pressure:
   ```bash
   stress-ng --vm 2 --vm-bytes 85% --timeout 360s &
   ```
   Confirm `HighMemoryWarning` fires. Screenshot.

---

## Evidence checklist

For each scenario, collect:
- [ ] Trigger screenshot (workflow failure / tc command / stress-ng)
- [ ] Dashboard showing degradation
- [ ] Alert firing in #DevOps-Alerts with full structured payload
- [ ] Trace in Tempo (Scenario 2)
- [ ] Recovery alert in #DevOps-Alerts
- [ ] Dashboard showing return to normal
