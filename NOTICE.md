# Attribution

The bundled-Traefik deployment flow was informed by:

- NetBird's official self-hosted quickstart and combined-server configuration,
  checked at commit `1e5b0a5c892750c36d3f53e2d825632a81ed98d1`.
- The `getting-started` branch of
  [PizzaLovingNerd/ansible-netbird](https://github.com/PizzaLovingNerd/ansible-netbird/tree/getting-started),
  inspected at commit `4a137b785c8ed1a2a9c15f4e50b587bea0a4110e`.
- Akamai's
  [Marketplace app development conventions](https://github.com/akamai-compute-marketplace/marketplace-apps).

This implementation is intentionally narrower than the referenced Ansible
playbook. It supports only NetBird's embedded identity provider and its bundled
Traefik reverse proxy. It does not include external proxies, NetBird's optional
application proxy, CrowdSec, or configuration-as-code resources.
