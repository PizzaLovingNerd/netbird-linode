# Test the NetBird StackScript

The meaningful end-to-end test is a new Ubuntu 24.04 Linode. The StackScript
installs system packages, changes SSH and firewall policy, uses the instance's
public IPv4 address, and requests a real TLS certificate, so it should not be
run on an existing server.

## 1. Prepare DNS

Choose one of these paths:

- **Linode DNS:** create the DNS zone first, then supply a short-lived Linode
  API token with Domains read/write access. The deployment creates or updates
  the requested A record.
- **Other DNS provider:** create the A record before deployment. It must resolve
  to the test Linode's public IPv4 address. A temporary wildcard record can be
  useful when the address is not known until the instance is created.

Use a test hostname such as `netbird-test.example.com`, not the production
hostname.

## 2. Create an Account StackScript

1. Open **Cloud Manager > StackScripts > Create StackScript**.
2. Use a label such as `NetBird development test`.
3. Paste the complete contents of
   `deployment_scripts/linode-marketplace-netbird/netbird-deploy.sh`.
4. Select **Ubuntu 24.04 LTS** as the compatible image.
5. Keep the StackScript private while testing.

## 3. Deploy a disposable instance

Deploy the Account StackScript with:

- Ubuntu 24.04 LTS
- a Shared CPU plan with at least 2 GB RAM
- the test DNS zone and subdomain
- a valid Let's Encrypt contact email
- an SSH public key
- **Disable root access over SSH:** `Yes`

If the DNS zone is hosted by Linode, provide the scoped API token. Otherwise,
leave the token field empty and confirm the hostname already points to the new
instance.

Provisioning normally takes 5–10 minutes. Follow it from the Lish console, or
SSH into the instance and run:

```bash
sudo tail -f /var/log/stackscript.log
```

The final log line should be:

```text
[info] NetBird installation complete.
```

## 4. Verify the deployment

Replace `netbird-test.example.com` below with the test hostname.

```bash
curl --fail --silent --show-error \
  https://netbird-test.example.com/oauth2/.well-known/openid-configuration \
  >/dev/null && echo "OIDC endpoint healthy"
```

On the Linode, verify containers and host policy:

```bash
cd /opt/netbird
sudo docker compose ps
sudo docker compose logs --tail=200
sudo ufw status verbose
sudo ss -lntup
```

The test passes when:

- `netbird-server`, `dashboard`, and `traefik` are running
- the OIDC request succeeds with a trusted HTTPS certificate
- UFW permits `22/tcp`, `80/tcp`, `443/tcp`, and `3478/udp`
- no unexpected public application ports are listening
- `https://netbird-test.example.com/setup` displays the first-admin wizard

Create the first administrator, install a NetBird client on two devices, enroll
both devices, and verify that each can reach the other's NetBird IP. This tests
the management API, embedded identity provider, signal service, relay/STUN
path, and peer networking rather than only the dashboard.

## 5. Clean up

Delete the disposable Linode and its test DNS record after the test. Revoke the
temporary Domains token if one was created for this deployment.
