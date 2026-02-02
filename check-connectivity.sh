#!/bin/bash
# Run this on the EC2 server to diagnose why self.plumoai.com times out.

set -e
echo "=== PlumoAI connectivity check (run on server) ==="
echo ""

echo "1. Docker containers (traefik should be Up):"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "  Docker not running or not in PATH."
echo ""

echo "2. Ports 80 and 443 listening:"
(ss -tlnp 2>/dev/null || netstat -tlnp 2>/dev/null) | grep -E ':(80|443)\s' || echo "  No process listening on 80/443."
echo ""

echo "3. Curl from server to localhost (bypasses firewall):"
if curl -sS -o /dev/null -w "%{http_code}" --connect-timeout 5 http://127.0.0.1 2>/dev/null; then
  echo "  -> http://127.0.0.1 OK"
else
  echo "  -> http://127.0.0.1 FAILED (Traefik may not be running or not bound to 0.0.0.0)"
fi
if curl -sS -o /dev/null -w "%{http_code}" --connect-timeout 5 -k https://127.0.0.1 2>/dev/null; then
  echo "  -> https://127.0.0.1 OK"
else
  echo "  -> https://127.0.0.1 FAILED or no cert yet"
fi
echo ""

echo "4. DNS for self.plumoai.com:"
getent hosts self.plumoai.com 2>/dev/null || host self.plumoai.com 2>/dev/null || echo "  Could not resolve."
echo ""

echo "--- If localhost works but browser times out ---"
echo "  • AWS: EC2 -> Security Groups -> Inbound rules: allow 80 and 443 from 0.0.0.0/0"
echo "  • DNS: self.plumoai.com must A-record to this instance PUBLIC IP"
echo "  • Optional: disable or allow 80/443 in instance firewall (firewalld/ufw/iptables)"
echo ""
