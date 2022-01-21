#!/bin/bash
set -euo pipefail

DIR=/docker-entrypoint.d

if [[ -d "$DIR" ]] ; then
  echo "Executing entrypoint scripts in $DIR"
  /bin/run-parts --exit-on-error "$DIR"
fi

# Update environment according to entrypoint logic
if [[ -f "${SECURITY_OUTPUT_DIR:-/var/tmp/teku}/.env" ]]; then
  source "${SECURITY_OUTPUT_DIR:-/var/tmp/teku}/.env" || true
fi

if [[ -n "${EXTRA_ARGS:-""}" ]]; then
  exec /usr/bin/tini -g -- $@ ${EXTRA_ARGS}
else
  exec /usr/bin/tini -g -- "$@"
fi
