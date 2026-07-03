#!/bin/bash
# Shared by sa-hook-create.sh/sa-hook-remove.sh: translates the named "--key=value" flags that the
# generic service-account-producer-sidecar passes into the bare positional "key=value" parameters
# that create-sa.sh/remove-sa.sh expect

#######################################
# Reads named "--key=value" flags plus the trailing consumer argument, validates each flag's key
# against an explicit, ordered allowlist, and builds the positional PLAIN_PARAMS array in that
# fixed order - regardless of the order the flags actually arrived in.
# GLOBALS:
#   PLAIN_PARAMS (out)
#   CONSUMER (out)
# ARGUMENTS:
#   #1   - space-separated, ordered list of known parameter keys, e.g. "fullAccessRepository permissions"
#   #2.. - [--key=value...] <consumer>, as received from the sidecar
#######################################
function readKnownParams() {
  local ordered_known_keys="$1"
  shift

  local number_of_args=$#
  # shellcheck disable=SC2034 # CONSUMER/PLAIN_PARAMS are intentionally global for callers of this function.
  CONSUMER="${!number_of_args}"

  declare -A values=()
  if [ "${number_of_args}" -gt 1 ]; then
    local flag key value
    for flag in "${@:1:$((number_of_args - 1))}"; do
      key="${flag%%=*}"
      key="${key#--}"
      value="${flag#*=}"

      if [[ " ${ordered_known_keys} " != *" ${key} "* ]]; then
        echo "unknown parameter: ${key}" >&2
        exit 1
      fi
      values["${key}"]="${value}"
    done
  fi

  PLAIN_PARAMS=()
  local known_key
  for known_key in ${ordered_known_keys}; do
    if [ -n "${values[${known_key}]+set}" ]; then
      PLAIN_PARAMS+=("${known_key}=${values[${known_key}]}")
    fi
  done
}
