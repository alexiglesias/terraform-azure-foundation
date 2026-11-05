#!/usr/bin/env bash
# =============================================================================
# read-secret.sh - runs ON the VM (through `az vm run-command`) and proves the
# VM's managed identity can read a Key Vault secret. It never prints the
# secret itself, only the HTTP status and the secret's length.
#
# Usage (from the repo root - the exact command is a Terraform output):
#   terraform -chdir=envs/dev output -raw read_secret_command
#
# How it works:
#   1. Ask the Instance Metadata Service (169.254.169.254, reachable only
#      from inside the VM) for a token for Key Vault. No password or key is
#      involved - Azure vouches for the VM's identity.
#   2. Use the token to GET the secret from Key Vault.
#      200 = allowed, 403 = the identity has no access to that secret.
# =============================================================================
set -euo pipefail

VAULT="${1:?usage: read-secret.sh <vault-name> <secret-name>}"
SECRET="${2:?usage: read-secret.sh <vault-name> <secret-name>}"

TOKEN="$(curl -s -H Metadata:true \
  "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net" \
  | python3 -c 'import json, sys; print(json.load(sys.stdin)["access_token"])')"

BODY="$(mktemp)"
trap 'rm -f "${BODY}"' EXIT

STATUS="$(curl -s -o "${BODY}" -w '%{http_code}' --max-time 15 \
  -H "Authorization: Bearer ${TOKEN}" \
  "https://${VAULT}.vault.azure.net/secrets/${SECRET}?api-version=7.4" || true)"

echo "Vault: ${VAULT}  Secret: ${SECRET}  HTTP ${STATUS}"
python3 - "${BODY}" <<'PY'
import json, sys
try:
    data = json.load(open(sys.argv[1]))
except ValueError:
    print("No JSON body (network problem or timeout).")
    sys.exit(0)
if "value" in data:
    print(f"OK: secret read, length {len(data['value'])} characters (value not shown)")
else:
    print("DENIED:", data.get("error", {}).get("code", "unknown"), "-", data.get("error", {}).get("message", ""))
PY
