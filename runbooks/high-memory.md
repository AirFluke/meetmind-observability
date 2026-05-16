# Runbook: High Memory Usage

## What is this alert?

**Alert:** `HighMemoryWarning` / `HighMemoryCritical`

Memory utilisation has exceeded 80% (warning) or 90% (critical).

## Likely cause

- Application memory leak (e.g. unbounded cache, connection pool growth)
- Loki or Prometheus ingesting more data than expected
- OOM killer not triggered yet but system is under pressure
- Swap exhaustion compounding the issue

## First 3 investigation steps

1. Identify the memory consumer: `ps aux --sort=-%mem | head -20`
2. Check for memory leaks: `journalctl -u <service> | grep -i "oom\|memory\|heap"`
3. Check if swap is in use: `free -h && swapon --show`

## Resolution

- Restart the leaking service: `sudo systemctl restart <service>`
- Increase memory limit or add swap:
  ```bash
  sudo fallocate -l 2G /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile
  ```
- If Loki or Prometheus: reduce retention or ingestion rate in config

## Rollback criteria

Roll back if memory spike started within 30 minutes of a deployment.

## Escalation

Escalate if memory stays > 90% after restart, or if the server becomes unresponsive.
Contact: Engineering lead → on-call manager.
