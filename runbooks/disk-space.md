# Runbook: Disk Space

## What is this alert?

**Alert:** `DiskSpaceWarning` (75%) / `DiskSpaceCritical` (90%)

Disk usage on the root filesystem has exceeded the threshold.

## Likely cause

- Prometheus TSDB or Loki chunks growing beyond retention limits
- Log files filling up (journald, application logs)
- Tempo trace data accumulation
- Failed cleanup of temporary files

## First 3 investigation steps

1. Find the large directories: `du -sh /* 2>/dev/null | sort -rh | head -20`
2. Check observability data sizes: `du -sh /var/lib/prometheus /var/lib/loki /var/lib/tempo`
3. Check journal logs: `journalctl --disk-usage`

## Resolution

- Clean old journal logs: `sudo journalctl --vacuum-size=500M`
- Reduce Prometheus retention: edit `--storage.tsdb.retention.time` in the systemd unit file
- Reduce Loki retention: edit `retention_period` in `/etc/loki/loki-config.yaml`
- Remove old Tempo traces: check compactor settings in `/etc/tempo/tempo.yaml`
- Clear apt cache: `sudo apt-get clean`

## Rollback criteria

Not typically deployment-related. If disk filled after a config change, revert the config.

## Escalation

If disk is > 95% and cannot be freed: escalate immediately — filesystem full = service down.
Contact: Engineering lead immediately.
