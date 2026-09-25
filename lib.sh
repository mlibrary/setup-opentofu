#!/bin/bash
# Shared helpers for resolve.sh and install.sh.

STABLE_RE='^[0-9]+\.[0-9]+\.[0-9]+$'
PRERELEASE_RE='^[0-9]+\.[0-9]+\.[0-9]+-[a-z]+[0-9]+$'

onoe() {
  echo "::error::$1" >&2
  exit 1
}

validate_version() {
  local name="$1"
  local version="$2"
  if [[ "$version" =~ $STABLE_RE ]]; then
    return 0
  fi
  if [[ "$version" =~ $PRERELEASE_RE ]]; then
    if [[ "${ALLOW_PRERELEASE:-false}" == "true" ]]; then
      return 0
    fi
    onoe "${name} version '${version}' is a prerelease. Set allow_prerelease: true to use prerelease versions."
  fi
  onoe "${name} version '${version}' is not a valid version string."
}

read_version_file() {
  local name="$1"
  local file="$2"
  [[ -f "${file}" ]] || onoe "${name} version file '${file}' does not exist."
  local ver
  read -r ver < "${file}" || true
  ver="${ver#"${ver%%[![:space:]]*}"}"
  ver="${ver%"${ver##*[![:space:]]}"}"
  [[ -n "${ver}" ]] || onoe "${name} version file '${file}' is empty."
  echo "${ver}"
}

# Sets ARCH to the GitHub Actions convention arch name (amd64/arm64), based on
# the current machine's architecture.
resolve_arch() {
  case "${MACHTYPE}" in
    x86_64*)  ARCH="amd64" ;;
    aarch64*) ARCH="arm64" ;;
    *) onoe "Unsupported architecture: ${MACHTYPE}" ;;
  esac
}
