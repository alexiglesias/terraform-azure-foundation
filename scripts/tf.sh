#!/usr/bin/env bash
# =============================================================================
# tf.sh - one safe entry point for every Terraform action on an environment.
#
# Usage:
#   scripts/tf.sh <env> <plan|apply|destroy|output> [--yes]
#
#   plan     show what would change. Changes NOTHING.
#   apply    plan -> show it -> ask -> apply exactly that plan
#   destroy  plan -destroy -> ask -> apply exactly that plan
#   output   print the environment's outputs
#
#   --yes    don't ask (also implied when CI=true) - for pipelines only
#
# Safety built in:
#   - you confirm AFTER seeing the plan, and Terraform applies the saved plan
#     file, so what runs is exactly what you approved
#   - checks you are logged in to Azure, and to the subscription pinned in
#     envs/<env>/terraform.tfvars, before touching anything
# =============================================================================
set -euo pipefail

usage() {
  sed -n '5,13p' "$0" | sed 's/^# \{0,1\}//'
  exit 1
}

TARGET="${1:-}"
ACTION="${2:-}"
AUTO_APPROVE=false
[ "${CI:-}" = "true" ] && AUTO_APPROVE=true
[ "${3:-}" = "--yes" ] && AUTO_APPROVE=true

[ -n "${TARGET}" ] || usage
case "${ACTION}" in plan|apply|destroy|output) ;; *) usage ;; esac

cd "$(dirname "$0")/.."
ENV_DIR="envs/${TARGET}"
INIT_ARGS=(-backend-config=backend.hcl)

info() { echo "[INFO] $*"; }
die()  { echo "[ERROR] $*" >&2; exit 1; }
tf()   { terraform -chdir="${ENV_DIR}" "$@"; }

[ -d "${ENV_DIR}" ] || die "No such environment: ${ENV_DIR}"

# Ask the user to type a word; skipped with --yes / CI=true.
confirm() {
  local word="$1" prompt="$2" answer
  if [ "${AUTO_APPROVE}" = true ]; then
    info "Auto-approved (--yes / CI)."
    return 0
  fi
  read -r -p "${prompt} Type '${word}' to continue: " answer
  [ "${answer}" = "${word}" ] || { echo "Aborted. Nothing was changed."; exit 1; }
}

# -----------------------------------------------------------------------------
# Pre-flight: right files, right login, right subscription
# -----------------------------------------------------------------------------
preflight() {
  [ -f "${ENV_DIR}/backend.hcl" ] \
    || die "${ENV_DIR}/backend.hcl not found - run the bootstrap first (terraform -chdir=bootstrap apply)."

  # In CI the pipeline signs in with OIDC and passes values as TF_VAR_*,
  # so there is no az login and no terraform.tfvars to compare against.
  if [ "${ARM_USE_OIDC:-}" = "true" ]; then
    info "CI / OIDC sign-in - skipping the az login check."
    return 0
  fi

  [ -f "${ENV_DIR}/terraform.tfvars" ] \
    || die "${ENV_DIR}/terraform.tfvars not found: cp ${ENV_DIR}/terraform.tfvars.example ${ENV_DIR}/terraform.tfvars"
  command -v az >/dev/null 2>&1 || die "Azure CLI (az) not found."

  local current user pinned
  if ! current="$(az account show --query id -o tsv 2>/dev/null)"; then
    die "Not logged in to Azure. Run: az login"
  fi
  user="$(az account show --query user.name -o tsv)"
  pinned="$(sed -n 's/^[[:space:]]*subscription_id[[:space:]]*=[[:space:]]*"\([0-9a-f-]*\)".*/\1/p' "${ENV_DIR}/terraform.tfvars" | head -1)"

  [ -n "${pinned}" ] || die "subscription_id is not set in ${ENV_DIR}/terraform.tfvars."
  [ "${current}" = "${pinned}" ] \
    || die "az is on subscription ${current}, but terraform.tfvars pins ${pinned}. Run: az account set -s ${pinned}"

  info "Azure subscription ${current} as ${user}"
}

# terraform init, quiet unless it fails.
tf_init() {
  local log
  if ! log="$(tf init -input=false "${INIT_ARGS[@]}" 2>&1)"; then
    echo "${log}" >&2
    die "terraform init failed."
  fi
}

# Run a plan into a file. Sets PLAN_RC: 0 = no changes, 2 = changes.
run_plan() {
  local planfile="$1"
  shift
  set +e
  tf plan -input=false -detailed-exitcode -out="${planfile}" "$@"
  PLAN_RC=$?
  set -e
  [ "${PLAN_RC}" -ne 1 ] || die "terraform plan failed."
}

free_tier_note() {
  echo
  echo "  Designed for the Azure free account: B2pts_v2/B2ats_v2 VM (750 free hours/month),"
  echo "  one 64 GB P6 disk, LRS state storage. Nothing here has an hourly charge outside"
  echo "  those allowances. Tear down with:  make destroy"
  echo
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
command -v terraform >/dev/null 2>&1 || die "terraform not found."

if [ "${ACTION}" = "output" ]; then
  tf_init
  tf output
  exit 0
fi

preflight
tf_init

case "${ACTION}" in
  plan)
    run_plan tfplan
    rm -f "${ENV_DIR}/tfplan"
    if [ "${PLAN_RC}" -eq 0 ]; then
      info "No changes."
    else
      info "Plan only - nothing was changed."
    fi
    ;;

  apply)
    run_plan tfplan
    if [ "${PLAN_RC}" -eq 0 ]; then
      rm -f "${ENV_DIR}/tfplan"
      info "No changes - infrastructure already matches the code."
      exit 0
    fi
    free_tier_note
    confirm "yes" "Apply the plan above to ${TARGET}?"
    tf apply -input=false tfplan
    rm -f "${ENV_DIR}/tfplan"
    ;;

  destroy)
    run_plan destroy.tfplan -destroy
    if [ "${PLAN_RC}" -eq 0 ]; then
      rm -f "${ENV_DIR}/destroy.tfplan"
      info "Nothing to destroy."
      exit 0
    fi
    confirm "destroy" "DESTROY everything listed above in ${TARGET}?"
    tf apply -input=false destroy.tfplan
    rm -f "${ENV_DIR}/destroy.tfplan"
    info "Done. bootstrap/ (state storage + budget) is kept on purpose - it costs ~0."
    ;;
esac
