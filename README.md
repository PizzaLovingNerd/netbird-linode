# NetBird Linode One-Click App

This repository contains a self-contained Linode Marketplace deployment for a
single-node, self-hosted NetBird control plane on Ubuntu 24.04 LTS.

The deployment follows Linode's StackScript + Ansible convention. It installs
Docker, creates a limited sudo user, configures UFW and Fail2ban, optionally
creates a Linode DNS record, and starts:

- `netbirdio/netbird-server` with the embedded identity provider
- `netbirdio/dashboard`
- an internal Traefik container with automatic Let's Encrypt TLS

It deliberately excludes every alternate proxy path and the optional NetBird
application reverse proxy/CrowdSec stack from the reference playbook.

## Repository layout

```text
deployment_scripts/linode-marketplace-netbird/
  netbird-deploy.sh       Linode StackScript
  linode-config.sh        CI deployment defaults
  test-vars.sh            Local/CI UDF defaults
apps/linode-marketplace-netbird/
  provision.yml           Limited-user provisioning
  site.yml                Host and NetBird installation
  roles/                  Self-contained Ansible roles
```

## Use as a StackScript

1. In Cloud Manager, create an Account StackScript.
2. Paste the contents of
   `deployment_scripts/linode-marketplace-netbird/netbird-deploy.sh`.
3. Select Ubuntu 24.04 LTS as the compatible image.
4. Deploy the StackScript on a plan with at least 2 GB RAM.

For a Marketplace monorepo submission, change `DEFAULT_GIT_REPO` to the target
monorepo and retain `MARKETPLACE_APP=apps/linode-marketplace-netbird`.

See the app [README](apps/linode-marketplace-netbird/README.md) and
[deployment documentation](apps/linode-marketplace-netbird/DOCUMENTATION.md)
for inputs, firewall ports, DNS behavior, and maintenance.
Use [TESTING.md](TESTING.md) for a clean-instance smoke test and its pass/fail
checks.

This project is licensed under GPL-3.0; see [LICENSE](LICENSE) and
[NOTICE.md](NOTICE.md).
