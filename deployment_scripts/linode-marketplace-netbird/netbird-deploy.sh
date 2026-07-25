#!/bin/bash

# NetBird Linode Marketplace StackScript

set -Eeuo pipefail
umask 077
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1

## NetBird settings
#<UDF name="domain" label="DNS zone" example="example.com">
#<UDF name="subdomain" label="NetBird subdomain (use @ for the zone apex)" example="netbird" default="netbird">
#<UDF name="acme_email" label="Email address for Let's Encrypt" example="admin@example.com">
#<UDF name="token_password" label="Linode API token for automatic DNS (optional if DNS already points here)" default="">

## Linode/SSH security settings
#<UDF name="user_name" label="Limited sudo username (lowercase letters, numbers, _ and -)" default="netbirdadmin">
#<UDF name="disable_root" label="Disable root access over SSH?" oneOf="Yes,No" default="Yes">

readonly DEFAULT_GIT_REPO="https://github.com/PizzaLovingNerd/netbird-linode.git"
readonly REPO_URL="${GIT_REPO:-${DEFAULT_GIT_REPO}}"
readonly REPO_BRANCH="${BRANCH:-main}"
readonly WORK_DIR="/tmp/netbird-linode-marketplace"
readonly CLONE_DIR="${WORK_DIR}.clone"
readonly MARKETPLACE_APP="apps/linode-marketplace-netbird"

cleanup() {
  local exit_code=$?

  if [[ ${exit_code} -eq 0 ]]; then
    [[ ! -d "${WORK_DIR}" ]] || rm -rf -- "${WORK_DIR}"
    [[ ! -d "${CLONE_DIR}" ]] || rm -rf -- "${CLONE_DIR}"
  elif [[ ${exit_code} -ne 0 ]]; then
    echo "[error] NetBird provisioning failed with exit code ${exit_code}."
    echo "[error] Review /var/log/stackscript.log for the failed task."
  fi
}

report_error() {
  local exit_code=$?
  local line_number="${BASH_LINENO[0]:-unknown}"

  echo "[error] Command failed near line ${line_number}: ${BASH_COMMAND}"
  return "${exit_code}"
}

retry() {
  local max_attempts="$1"
  local delay_seconds="$2"
  local attempt=1
  shift 2

  until "$@"; do
    if (( attempt >= max_attempts )); then
      echo "[error] Command failed after ${max_attempts} attempts: $*"
      return 1
    fi

    echo "[warning] Attempt ${attempt}/${max_attempts} failed; retrying in ${delay_seconds}s: $*"
    sleep "${delay_seconds}"
    attempt=$((attempt + 1))
  done
}

clone_repository() {
  if [[ -e "${CLONE_DIR}" ]]; then
    rm -rf -- "${CLONE_DIR}"
  fi

  git clone --depth 1 --branch "${REPO_BRANCH}" -- "${REPO_URL}" "${CLONE_DIR}"
}

trap report_error ERR
trap cleanup EXIT

run() {
  export DEBIAN_FRONTEND=noninteractive

  if [[ ${EUID} -ne 0 ]]; then
    echo "[error] The NetBird StackScript must run as root."
    return 1
  fi

  retry 5 10 apt-get -o Acquire::Retries=5 update
  retry 5 10 apt-get -o Acquire::Retries=5 install -y \
    dnsutils git openssh-client openssl python3 python3-pip python3-venv

  if [[ -e "${WORK_DIR}" || -e "${CLONE_DIR}" ]]; then
    echo "[error] Refusing to overwrite an existing deployment work directory."
    echo "[error] Remove ${WORK_DIR} and ${CLONE_DIR} only after inspecting them."
    return 1
  fi

  retry 5 10 clone_repository
  mv -- "${CLONE_DIR}" "${WORK_DIR}"

  cd "${WORK_DIR}/${MARKETPLACE_APP}"
  python3 -m venv env
  # shellcheck source=/dev/null
  source env/bin/activate
  retry 5 10 python -m pip install --retries 5 --timeout 30 --upgrade pip
  retry 5 10 python -m pip install --retries 5 --timeout 30 -r requirements.txt
  retry 5 10 ansible-galaxy collection install -r collections.yml

  ansible-playbook -v preflight.yml
  ansible-playbook -v provision.yml
  ansible-playbook -v site.yml
}

run
echo "[info] NetBird installation complete."
