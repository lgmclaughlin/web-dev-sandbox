#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

export PATH=/sbin:/bin:/usr/sbin:/usr/bin

echo "Starting Docker firewall setup..."

if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: Cannot run without root priveleges"
  exit 1
fi

DOCKER_DNS_RULES=$(iptables-save -t nat | grep "127\.0\.0\.11" || true)

iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X

ipset destroy git-domains 2>/dev/null || true
ipset create git-domains hash:net

ipset destroy allowed-domains 2>/dev/null || true
ipset create allowed-domains hash:net

if [ -n "$DOCKER_DNS_RULES" ]; then
  echo "Restoring Docker DNS rules..."
  iptables -t nat -N DOCKER_OUTPUT 2>/dev/null || true
  iptables -t nat -N DOCKER_POSTROUTING 2>/dev/null || true
  echo "$DOCKER_DNS_RULES" | xargs -L 1 iptables -t nat
else
  echo "WARNING: No Docker DNS rules found"
fi

iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A INPUT  -p udp --sport 53 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT

iptables -A OUTPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT  -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT

iptables -A INPUT  -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

echo "Fetching GitHub IP ranges..."
gh_ranges=$(curl -fsSL -A "Docker-Firewall-Script" https://api.github.com/meta || echo "")

if [ -n "$gh_ranges" ]; then
  echo "Adding GitHub IP ranges..."
  echo "$gh_ranges" \
    | jq -r '(.web + .api + .git)[]' \
    | aggregate -q \
    | while read -r cidr; do
        ipset add git-domains "$cidr"
      done
else
  echo "WARNING: Could not fetch GitHub IPs, skipping..."
fi

HOST_IP=$(ip route | awk '/default/ {print $3}')
HOST_NETWORK="${HOST_IP%.*}.0/24"

iptables -A INPUT  -s "$HOST_NETWORK" -j ACCEPT
iptables -A OUTPUT -d "$HOST_NETWORK" -j ACCEPT

iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

iptables -A INPUT  -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

iptables -A OUTPUT -m set --match-set git-domains dst -j ACCEPT
iptables -A OUTPUT -m set --match-set allowed-domains dst -j ACCEPT

iptables -A OUTPUT -j REJECT --reject-with icmp-admin-prohibited

echo "Verifying firewall..."

if curl --connect-timeout 5 https://example.com >/dev/null 2>&1; then
  echo "ERROR: Firewall leak detected"
fi

if ! curl --connect-timeout 5 https://api.github.com/zen >/dev/null 2>&1; then
  echo "ERROR: GitHub connectivity failed"
fi

echo "Done."
