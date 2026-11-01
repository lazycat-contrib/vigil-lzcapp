#!/bin/sh
# Fit the packaged Vigil config to this deployment, then start the server.
#
# Two values must not ship as-is: the manager and reporter tokens protect the
# management API, and upstream's sample leaves placeholders in the file. They
# are rendered here from the platform's stable secrets so every deployment gets
# its own, and the rendered config is written to tmpfs rather than the image.
set -eu

CONF_SRC=/lzcapp/pkg/content/config.cfg
CONF_DIR=/run/vigil
CONF="$CONF_DIR/config.cfg"

MANAGER_TOKEN="${VIGIL_MANAGER_TOKEN:-}"
REPORTER_TOKEN="${VIGIL_REPORTER_TOKEN:-}"

fail() {
    echo "[vigil] refusing to start: $1" >&2
    exit 1
}

[ -n "$MANAGER_TOKEN" ] || fail "VIGIL_MANAGER_TOKEN must be set"
[ -n "$REPORTER_TOKEN" ] || fail "VIGIL_REPORTER_TOKEN must be set"
[ "${#MANAGER_TOKEN}" -ge 16 ] || fail "VIGIL_MANAGER_TOKEN must be at least 16 characters"
[ "${#REPORTER_TOKEN}" -ge 16 ] || fail "VIGIL_REPORTER_TOKEN must be at least 16 characters"

case "$MANAGER_TOKEN$REPORTER_TOKEN" in
    *[!A-Za-z0-9_-]*) fail "tokens may only contain letters, digits, _ and -" ;;
esac
[ "$MANAGER_TOKEN" != "$REPORTER_TOKEN" ] || fail "manager and reporter tokens must differ"

mkdir -p "$CONF_DIR"
chmod 700 "$CONF_DIR"

sed \
    -e "s|__VIGIL_MANAGER_TOKEN__|$MANAGER_TOKEN|" \
    -e "s|__VIGIL_REPORTER_TOKEN__|$REPORTER_TOKEN|" \
    "$CONF_SRC" > "$CONF"
chmod 600 "$CONF"

cd /usr/src/vigil
exec /usr/local/bin/vigil -c "$CONF"
