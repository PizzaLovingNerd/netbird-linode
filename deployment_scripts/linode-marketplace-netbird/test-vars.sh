#!/bin/bash

set -euo pipefail

export USER_NAME="${USER_NAME:-netbirdadmin}"
export DISABLE_ROOT="${DISABLE_ROOT:-No}"
export PUBKEY="${PUBKEY:-}"
export DOMAIN="${DOMAIN:-example.com}"
export SUBDOMAIN="${SUBDOMAIN:-netbird}"
export ACME_EMAIL="${ACME_EMAIL:-admin@example.com}"
export TOKEN_PASSWORD="${TOKEN_PASSWORD:-}"
