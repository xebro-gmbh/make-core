#!/usr/bin/env bash
set -euo pipefail

PROJECT_NAME="${XO_PROJECT_NAME:-dev-setup}"
ROOT_DIR="${XO_ROOT_DIR:-$(pwd)}"
CERT_DIR="${ROOT_DIR}/docker/config/cert"
CERT_FILE="${CERT_DIR}/local.crt"
KEY_FILE="${CERT_DIR}/local.key"
DOMAIN="${XO_SERVER_NAME:-${PROJECT_NAME}.bob}"
HOSTS_FILE="/etc/hosts"
HOSTS_UPDATE="${XO_HOSTS_UPDATE:-true}"
CERT_FORCE="${XO_CERT_FORCE:-false}"

mkdir -p "${CERT_DIR}"

if ! command -v openssl >/dev/null 2>&1; then
  printf "[core] openssl is required to generate local TLS certificates.\n" >&2
  exit 1
fi

CERT_REUSED="false"
if [[ "${CERT_FORCE}" != "true" && -f "${CERT_FILE}" && -f "${KEY_FILE}" ]] && openssl x509 -in "${CERT_FILE}" -noout -ext subjectAltName 2>/dev/null | grep -q "DNS:${DOMAIN}"; then
  CERT_REUSED="true"
  printf "[core] Reusing existing TLS certificate for %s\n" "${DOMAIN}"
fi

TMP_OPENSSL_CONFIG="$(mktemp)"
TMP_HOSTS_FILE="$(mktemp)"
trap 'rm -f "${TMP_OPENSSL_CONFIG}" "${TMP_HOSTS_FILE}"' EXIT

cat > "${TMP_OPENSSL_CONFIG}" <<EOF
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no

[req_distinguished_name]
CN = ${DOMAIN}

[v3_req]
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${DOMAIN}
DNS.2 = localhost
EOF

if [[ "${CERT_REUSED}" != "true" ]]; then
  if command -v mkcert >/dev/null 2>&1; then
    mkcert -cert-file "${CERT_FILE}" -key-file "${KEY_FILE}" "${DOMAIN}" localhost 127.0.0.1 ::1 >/dev/null 2>&1
    printf "[core] Generated TLS certificate via mkcert for %s\n" "${DOMAIN}"
  else
    openssl req -x509 -nodes -newkey rsa:2048 -sha256 -days 3650 \
      -keyout "${KEY_FILE}" \
      -out "${CERT_FILE}" \
      -config "${TMP_OPENSSL_CONFIG}" \
      -extensions v3_req >/dev/null 2>&1
    printf "[core] Generated self-signed TLS certificate (openssl) for %s\n" "${DOMAIN}"
  fi
fi

chmod 600 "${KEY_FILE}"
chmod 644 "${CERT_FILE}"

case "${HOSTS_UPDATE}" in
  true|TRUE|True|1|yes|YES|on|ON)
    if awk -v domain="${DOMAIN}" '
      /^[[:space:]]*#/ { next }
      {
        for (i = 2; i <= NF; i++) {
          if ($i == domain) {
            found = 1
          }
        }
      }
      END { exit(found ? 0 : 1) }
    ' "${HOSTS_FILE}"; then
      printf "[core] Hosts entry for %s already exists, skipping hosts update.\n" "${DOMAIN}"
    else
      awk '
        {
          keep = 1
          for (i = 2; i <= NF; i++) {
            if ($i ~ /\.bob$/) {
              keep = 0
              break
            }
          }
          if (keep) {
            print $0
          }
        }
      ' "${HOSTS_FILE}" > "${TMP_HOSTS_FILE}"

      printf "127.0.0.1 %s\n" "${DOMAIN}" >> "${TMP_HOSTS_FILE}"

      if [[ -w "${HOSTS_FILE}" ]]; then
        cp "${TMP_HOSTS_FILE}" "${HOSTS_FILE}"
      elif command -v sudo >/dev/null 2>&1; then
        sudo cp "${TMP_HOSTS_FILE}" "${HOSTS_FILE}"
      else
        printf "[core] Could not update %s automatically (missing write permission).\n" "${HOSTS_FILE}" >&2
        exit 1
      fi

      printf "[core] Updated %s: removed '*.bob' entries and set %s -> 127.0.0.1\n" "${HOSTS_FILE}" "${DOMAIN}"
    fi
    ;;
  *)
    printf "[core] Skipping hosts update (XO_HOSTS_UPDATE=%s).\n" "${HOSTS_UPDATE}"
    ;;
esac

if [[ "${CERT_REUSED}" == "true" ]]; then
  printf "[core] TLS certificate for %s remains in %s\n" "${DOMAIN}" "${CERT_DIR}"
else
  printf "[core] TLS certificate for %s written to %s\n" "${DOMAIN}" "${CERT_DIR}"
fi
