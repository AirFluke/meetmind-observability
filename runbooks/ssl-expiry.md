# Runbook: SSL Certificate Expiry

## What is this alert?

**Alert:** `SSLCertExpiringSoon` — SSL certificate expires in less than 14 days.

## Likely cause

- Auto-renewal (certbot) cron job failed or is not configured
- DNS records changed and ACME challenge can no longer validate
- Certificate was manually provisioned and has no renewal automation
- Let's Encrypt rate limits reached

## First 3 investigation steps

1. Confirm the certificate details:
   ```bash
   openssl s_client -connect <host>:443 2>/dev/null | openssl x509 -noout -dates
   ```
2. Check if certbot is installed and the renewal cron is running:
   ```bash
   sudo certbot renew --dry-run
   ```
3. Check DNS is pointing to the correct server:
   ```bash
   dig +short <domain>
   ```

## Resolution

- Renew immediately: `sudo certbot renew`
- Restart web server after renewal: `sudo systemctl reload nginx`
- If certbot is not installed, install and configure:
  ```bash
  sudo apt-get install -y certbot
  sudo certbot certonly --standalone -d <domain>
  ```

## Rollback criteria

Not applicable — certificate renewal is always safe.

## Escalation

If auto-renewal fails after manual retry: escalate to senior engineer.
Expired SSL = service unavailable for all HTTPS users.
