#!/bin/bash
set -e

# Simple bootstrap for the bastion host
# - updates packages
# - installs a few handy tools + Postgres client
# - sets a clear MOTD so you can confirm the script ran

dnf -y update || true
dnf -y install jq htop git postgresql || true

cat >/etc/motd <<'MOTD'
----------------------------------------
 Bastion ready (provisioned by Terraform)
 Connect via SSM Session Manager (no SSH keys).
 Tools: jq, htop, git, psql installed.
----------------------------------------
MOTD

# Leave a marker so you know bootstrap completed
echo "$(date -Is) - bastion bootstrap complete" | tee /var/local/bastion_bootstrap.done
