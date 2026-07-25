---
title: Deploy NetBird through the Linode Marketplace
description: Deploy a self-hosted NetBird control plane with embedded identity and automatic TLS.
published: 2026-07-24
keywords:
  - netbird
  - wireguard
  - vpn
  - zero trust
  - marketplace
tags:
  - networking
  - security
license: CC BY-ND 4.0
---

# Deploy NetBird through the Linode Marketplace

NetBird creates a peer-to-peer WireGuard network with centralized identity,
access policy, routing, and DNS management. This app installs NetBird's combined
server and embedded identity provider, the NetBird dashboard, and a private
Traefik container that handles public HTTPS and gRPC traffic.

## Before deployment

- Use Ubuntu 26.04 LTS. Ubuntu 24.04 LTS is also supported.
- Choose a Shared CPU plan with at least 2 GB RAM.
- Have an existing DNS zone and a valid email address.
- To create DNS automatically, create a Linode API token with Domains
  read/write access. The DNS zone must already exist in Linode DNS.
- If you do not provide a token, arrange for the requested hostname to resolve
  to the new Linode. A wildcard DNS record is convenient when the IPv4 address
  is not known before deployment.

## Configuration options

### NetBird settings

- **DNS zone:** The existing parent zone, for example `example.com`.
- **NetBird subdomain:** A relative name such as `netbird`. Enter `@` to use the
  zone apex.
- **Email address for Let's Encrypt:** Used by Traefik when creating the ACME
  account and certificate.
- **Linode API token:** Optional when DNS is managed outside Linode or the A
  record already exists. When supplied, the app creates or updates the A record
  to the Linode's primary public IPv4 address.

### Security settings

- **Limited sudo username:** The non-root Linux administrator created by the
  deployment.
- **Disable root access over SSH:** Prevents direct root SSH logins when set to
  `Yes`.

Select an account SSH key in the Linode creation form. Linode injects selected
keys into the root account, and the app copies them to the limited sudo user.
If the limited user receives at least one authorized key, the app disables SSH
password authentication. Otherwise, password authentication remains enabled.

## Deployment

Create a Compute Instance from the NetBird Marketplace app, fill in the fields,
and deploy. Installation normally takes 5–10 minutes after the instance boots.
The app waits for public DNS, obtains a trusted certificate, and verifies the
embedded identity provider before it reports success.

Provisioning output is written to:

```text
/var/log/stackscript.log
```

If deployment stops at the DNS task, verify that the requested hostname's A
record matches the instance's public IPv4 address.

## Access NetBird

Open:

```text
https://<subdomain>.<domain>
```

On the first visit, NetBird displays its setup wizard. Create the first NetBird
administrator there. No NetBird web password is written to disk by the
Marketplace app.

Linux credentials and access notes are stored at:

```text
/home/<limited-sudo-user>/.credentials
```

The file is owned by that user with mode `0600`.

## Operate the deployment

NetBird's Compose project is located at `/opt/netbird`.

View container status:

```bash
cd /opt/netbird
sudo docker compose ps
```

View logs:

```bash
cd /opt/netbird
sudo docker compose logs --tail=200
```

Restart the stack:

```bash
cd /opt/netbird
sudo docker compose restart
```

## Firewall

UFW allows only these inbound ports:

| Port | Protocol | Use |
| --- | --- | --- |
| 22 | TCP | SSH |
| 80 | TCP | HTTP redirect and Let's Encrypt |
| 443 | TCP | NetBird HTTPS, gRPC, WebSocket, and relay |
| 3478 | UDP | NetBird STUN |

The optional NetBird application reverse proxy is not installed, so this app
does not open `51820/udp` or configure wildcard application domains.

## Update NetBird

Container images are version-pinned for repeatable Marketplace deployments.
Before upgrading, review NetBird's release notes and backup guidance. Update the
image tags in `/opt/netbird/docker-compose.yml`, then run:

```bash
cd /opt/netbird
sudo docker compose pull
sudo docker compose up -d
```

Verify the deployment afterward:

```bash
curl --fail https://<netbird-hostname>/oauth2/.well-known/openid-configuration
sudo docker compose ps
```

## Backup

Back up all files under `/opt/netbird` and both the `netbird_data` and
`netbird_traefik_letsencrypt` Docker volumes. The first volume holds NetBird's
SQLite datastore and embedded identity data. The second holds Traefik's
certificate state. The project directory holds the encryption key, relay
secret, and server configuration.

Follow the current
[NetBird backup documentation](https://docs.netbird.io/selfhosted/maintenance/backup)
before restoring or upgrading a production deployment.

## Further information

- [Self-hosting quickstart](https://docs.netbird.io/selfhosted/selfhosted-quickstart)
- [Configuration file reference](https://docs.netbird.io/selfhosted/maintenance/configuration-files)
- [Troubleshooting](https://docs.netbird.io/selfhosted/troubleshooting)
- [NetBird community support](https://github.com/netbirdio/netbird/discussions)
