#!/bin/bash

# import_package_docker.sh
#
# Usage:
# ./import_package_docker.sh <container_id_or_name> <package.zip> <user> <pass> [activate yes|no] [archive yes|no] [port]
#
# Defaults:
# activate = yes
# archive  = yes
# port     = 5555
#
# Copies package into Docker container inbound dir and installs via Integration Server API.

# === Defaults ===
DEFAULT_PORT="5555"
INBOUND_PATH_IN_CONTAINER="/opt/softwareag/IntegrationServer/replicate/inbound"

# === Inputs ===
CONTAINER="$1"
PACKAGE_FILE="$2"
IS_USER="$3"
IS_PASS="$4"
ACTIVATE_ON_INSTALL="${5:-yes}"
ARCHIVE_ON_INSTALL="${6:-yes}"
IS_PORT="${7:-$DEFAULT_PORT}"

function usage() {
  echo "Usage: $0 <container_id_or_name> <package.zip> <user> <pass> [activate yes|no] [archive yes|no] [port]"
  echo "Defaults: activate=yes, archive=yes, port=5555"
  exit 1
}

function check_inputs() {
  if [[ -z "$CONTAINER" || -z "$PACKAGE_FILE" || -z "$IS_USER" || -z "$IS_PASS" ]]; then
    usage
  fi

  if [[ ! -f "$PACKAGE_FILE" ]]; then
    echo "❌ ERROR: Package file not found: $PACKAGE_FILE"
    exit 1
  fi

  if ! docker ps --format '{{.Names}}' | grep -qw "$CONTAINER"; then
    echo "❌ ERROR: Docker container not running or not found: $CONTAINER"
    exit 2
  fi
}

function copy_package_into_container() {
  echo "📦 Copying $PACKAGE_FILE into Docker container: $CONTAINER at $INBOUND_PATH_IN_CONTAINER"
  docker cp "$PACKAGE_FILE" "${CONTAINER}:${INBOUND_PATH_IN_CONTAINER}/" || {
    echo "❌ ERROR: Failed to copy package into container."
    exit 3
  }
}

function pretty_print_html_response() {
  local html="$1"

  echo "$html" \
    | tr '\n' ' ' \
    | sed -E 's:<(/?)TR>:\n:gI' \
    | grep -oP '<TD[^>]*>.*?</TD>.*?<TD[^>]*>.*?</TD>' \
    | sed -E 's:<TD[^>]*>(.*?)</TD>.*?<TD[^>]*>(.*?)</TD>:\1|\2:' \
    | sed -E 's:<[^>]+>::g' \
    | while IFS='|' read -r key value; do
        local emoji=""
        case "$key" in
          packageFile)        emoji="🗂️" ;;
          activateOnInstall)  emoji="⚙️" ;;
          archiveOnInstall)   emoji="📦" ;;
          message)
            if echo "$value" | grep -qiE "error|fail"; then
              emoji="❗"
            else
              emoji="📝"
            fi
            ;;
          *) emoji="🔹" ;;
        esac
        printf "  %s \033[1m%-20s\033[0m %s\n" "$emoji" "$key:" "$value"
      done
}

function import_package_via_http() {
  local package_name
  package_name=$(basename "$PACKAGE_FILE")

  echo "🔗 Invoking pub.packages:installPackage on Integration Server at port $IS_PORT..."

  response=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -u "${IS_USER}:${IS_PASS}" -X POST \
    "http://localhost:${IS_PORT}/invoke/pub.packages:installPackage" \
    -d "packageFile=${package_name}&activateOnInstall=${ACTIVATE_ON_INSTALL}&archiveOnInstall=${ARCHIVE_ON_INSTALL}")

  local http_status body
  http_status=$(echo "$response" | sed -n 's/^HTTP_STATUS://p')
  body=$(echo "$response" | sed '/^HTTP_STATUS:/d')

  if [[ "$http_status" == "200" ]]; then
    echo "✅ Package installed successfully:"
    pretty_print_html_response "$body"
  else
    echo "❌ Installation failed (HTTP $http_status):"
    pretty_print_html_response "$body"
    exit 4
  fi
}

# === Main ===
check_inputs
copy_package_into_container
import_package_via_http

