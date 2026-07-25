#!/bin/bash

# NetBird Linode Marketplace StackScript

exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1
set -Eeuo pipefail

## NetBird settings
#<UDF name="domain" label="DNS zone" example="example.com">
#<UDF name="subdomain" label="NetBird subdomain (use @ for the zone apex)" example="netbird" default="netbird">
#<UDF name="acme_email" label="Email address for Let's Encrypt" example="admin@example.com">
#<UDF name="token_password" label="Linode API token for automatic DNS (optional if DNS already points here)" default="">

## Linode/SSH security settings
#<UDF name="user_name" label="Limited sudo username (lowercase letters, numbers, _ and -)" default="netbirdadmin">
#<UDF name="disable_root" label="Disable root access over SSH?" oneOf="Yes,No" default="No">
#<UDF name="pubkey" label="SSH public key for the limited sudo user (optional)" default="">

readonly DEFAULT_GIT_REPO="https://github.com/PizzaLovingNerd/NetBird-linode.git"
readonly REPO_URL="${GIT_REPO:-${DEFAULT_GIT_REPO}}"
readonly REPO_BRANCH="${BRANCH:-main}"
readonly WORK_DIR="/tmp/netbird-linode-marketplace"
readonly MARKETPLACE_APP="apps/linode-marketplace-netbird"

cleanup() {
  local exit_code=$?

  if [[ ${exit_code} -eq 0 && -d "${WORK_DIR}" ]]; then
    rm -rf -- "${WORK_DIR}"
  elif [[ ${exit_code} -ne 0 ]]; then
    echo "[error] NetBird provisioning failed with exit code ${exit_code}."
    echo "[error] Review /var/log/stackscript.log for the failed task."
  fi
}

trap cleanup EXIT

run() {
  export DEBIAN_FRONTEND=noninteractive

  apt-get update
  apt-get install -y git python3 python3-pip python3-venv

  if [[ -e "${WORK_DIR}" ]]; then
    echo "[error] Refusing to overwrite existing work directory ${WORK_DIR}."
    return 1
  fi

  git clone --depth 1 --branch "${REPO_BRANCH}" -- "${REPO_URL}" "${WORK_DIR}"

  cd "${WORK_DIR}/${MARKETPLACE_APP}"
  python3 -m venv env
  # shellcheck source=/dev/null
  source env/bin/activate
  python -m pip install --upgrade pip
  python -m pip install -r requirements.txt
  ansible-galaxy collection install -r collections.yml

  ansible-playbook -v provision.yml
  ansible-playbook -v site.yml
}

run
echo "[info] NetBird installation complete."
