# Runbook: Host Down

## What is this alert?
**Alert:** `HostDown`
Blackbox Exporter HTTP probe has failed for 2+ consecutive minutes. The service is unreachable.

## Likely cause
1. Server crashed or rebooted
2. Application process exited (OOM kill, segfault)
3. Docker Compose stack stopped
4. Network partition between Blackbox and target
5. Port blocked by firewall rule change

## First 3 investigation steps

1. **Check if the server is reachable at all:**
   ```bash
   ping -c 3 YOUR_SERVER_IP
   curl -v http://YOUR_SERVER_IP:3000/api/health
   ```

2. **Check Docker Compose services:**
   ```bash
   ssh ubuntu@YOUR_SERVER_IP
   cd /opt/meetmind-observability
   docker compose ps
   docker compose logs --tail=50 grafana prometheus
   ```

3. **Check system journal:**
   ```bash
   sudo journalctl -n 100 --since "10 minutes ago"
   sudo dmesg | tail -30
   ```

## Resolution

- If container stopped: `docker compose up -d <service>`
- If all containers down: `docker compose up -d`
- If server rebooted: services should auto-restart (restart: unless-stopped in Compose)
- If OOM kill: increase memory limits in docker-compose.yml for the affected service

## Rollback criteria
If the outage followed a deployment, roll back immediately:
```bash
docker compose pull  # ensure you have previous images cached
docker compose up -d --scale <service>=0 && docker compose up -d
# Or pin a specific tag in docker-compose.yml and redeploy
```

## Escalation
Escalate to senior engineer if:
- Server is unreachable via SSH (may require AWS console access)
- Multiple services are down simultaneously without an obvious cause
- The outage persists more than 15 minutes
