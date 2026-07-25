# Linode NetBird Deployment One-Click App

NetBird is an open source networking platform that connects devices through a
secure WireGuard-based overlay. This Marketplace app deploys a self-hosted
NetBird control plane on one Linode using the current combined server, embedded
identity provider, web dashboard, and an internal Traefik reverse proxy.
Traefik obtains and renews a Let's Encrypt certificate automatically. The app
also creates a limited sudo account, configures Docker, UFW, and Fail2ban, and
can create the required A record when a Linode API token is supplied. The
deployment intentionally stays small: it does not install an external identity
provider, external proxy, CrowdSec, or NetBird's optional application reverse
proxy.

## Software included

| Software | Version | Description |
| --- | --- | --- |
| NetBird Server | 0.75.0 | Combined management, signal, relay, STUN, and embedded IdP server |
| NetBird Dashboard | 2.90.7 | Browser-based NetBird administration |
| Traefik | 3.7.1 | Internal HTTPS and gRPC reverse proxy |
| Docker Engine | Current stable | Container runtime installed from Docker's Ubuntu repository |
| Docker Compose | Current stable | Compose v2 plugin installed with Docker |

Supported distributions: Ubuntu 26.04 LTS and Ubuntu 24.04 LTS. New
deployments should use Ubuntu 26.04 LTS.

Suggested plan: a Shared CPU plan with at least 2 GB RAM.

## Deployment inputs

| Field | Required | Purpose |
| --- | --- | --- |
| DNS zone | Yes | Existing zone, such as `example.com` |
| NetBird subdomain | Yes | Relative name such as `netbird`, or `@` for the zone apex |
| Let's Encrypt email | Yes | Certificate expiration and account notices |
| Linode API token | No | Creates the A record when the zone uses Linode DNS |
| Limited sudo username | Yes | Administrative Linux account |
| Disable root SSH | Yes | Selects whether SSH permits direct root login |
| SSH public key | No | Adds a key to the limited sudo account |

When the API token is omitted, the requested FQDN must already resolve to the
new Linode's public IPv4 address. Provisioning waits for public DNS before
starting Traefik so certificate issuance cannot silently fail.

## Network ports

- `22/tcp`: SSH
- `80/tcp`: HTTP redirect and Let's Encrypt
- `443/tcp`: NetBird dashboard, API, relay, WebSocket, and gRPC
- `3478/udp`: NetBird STUN

## Installed files

- `/opt/netbird/docker-compose.yml`
- `/opt/netbird/config.yaml`
- `/opt/netbird/dashboard.env`
- `/home/<sudo-user>/.credentials`
- `/var/log/stackscript.log`

The first NetBird administrator is not pre-generated. Open the deployed URL and
create it in NetBird's secure first-run browser wizard.

## Resources

- [NetBird self-hosting quickstart](https://docs.netbird.io/selfhosted/selfhosted-quickstart)
- [NetBird self-hosted maintenance](https://docs.netbird.io/selfhosted/maintenance)
- [NetBird support](https://github.com/netbirdio/netbird/discussions)
- [Linode Marketplace app development](https://github.com/akamai-compute-marketplace/marketplace-apps)
