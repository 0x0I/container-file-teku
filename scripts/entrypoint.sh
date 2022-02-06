#!/bin/bash
set -eo pipefail

DIR=/docker-entrypoint.d

if [[ -d "$DIR" ]] ; then
  echo "Executing entrypoint scripts in $DIR"
  /bin/run-parts --exit-on-error "$DIR"
fi

# Update environment according to entrypoint logic
if [[ -f "${SECURITY_OUTPUT_DIR:-/var/tmp/teku}/.env" ]]; then
  source "${SECURITY_OUTPUT_DIR:-/var/tmp/teku}/.env" || true
fi

conf="${TEKU_CONFIG_DIR:-/etc/teku}/config.yml"
if [[ -z "${NOLOAD_CONFIG}" && -f "${conf}" ]]; then
  echo "Loading config at ${conf}..."
  run_args="--config-file=${conf} ${EXTRA_ARGS:-}"
else
  run_args=${EXTRA_ARGS:-""}
fi

exec /usr/bin/tini -g -- $@ ${run_args}
