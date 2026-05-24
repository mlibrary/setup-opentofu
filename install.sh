#!/bin/bash
set -euo pipefail

STABLE_RE='^[0-9]+\.[0-9]+\.[0-9]+$'
PRERELEASE_RE='^[0-9]+\.[0-9]+\.[0-9]+-[a-z]+[0-9]+$'

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
    echo "::error::${name} version '${version}' is a prerelease. Set allow_prerelease: true to use prerelease versions." >&2
    exit 1
  fi
  echo "::error::${name} version '${version}' is not a valid version string." >&2
  exit 1
}

detect_arch() {
  case "$(uname -m)" in
    x86_64)  echo "amd64" ;;
    aarch64) echo "arm64" ;;
    *)
      echo "::error::Unsupported architecture: $(uname -m)" >&2
      exit 1
      ;;
  esac
}

install_tofu() {
  local ver="$1"
  local arch="$2"
  local dir="$3"
  local deb="tofu_${ver}_${arch}.deb"
  local sums="tofu_${ver}_SHA256SUMS"
  local base_url="https://github.com/opentofu/opentofu/releases/download/v${ver}"

  echo "Downloading OpenTofu ${ver} (${arch})..."
  curl -fsSL -o "${dir}/${deb}"  "${base_url}/${deb}"
  curl -fsSL -o "${dir}/${sums}" "${base_url}/${sums}"

  echo "Verifying OpenTofu checksum..."
  (cd "${dir}" && grep "${deb}" "${sums}" | sha256sum --check --status)

  echo "Installing OpenTofu..."
  sudo dpkg -i "${dir}/${deb}"
}

install_terramate() {
  local ver="$1"
  local arch="$2"
  local dir="$3"
  local deb="terramate_${ver}_linux_${arch}.deb"
  local sums="checksums.txt"
  local base_url="https://github.com/terramate-io/terramate/releases/download/v${ver}"

  echo "Downloading Terramate ${ver} (${arch})..."
  curl -fsSL -o "${dir}/${deb}"  "${base_url}/${deb}"
  curl -fsSL -o "${dir}/${sums}" "${base_url}/${sums}"

  echo "Verifying Terramate checksum..."
  (cd "${dir}" && grep "${deb}" "${sums}" | sha256sum --check --status)

  echo "Installing Terramate..."
  sudo dpkg -i "${dir}/${deb}"
}

# --- main ---

validate_version "tofu_version" "${TOFU_VERSION}"
if [[ -n "${TERRAMATE_VERSION:-}" ]]; then
  validate_version "terramate_version" "${TERRAMATE_VERSION}"
fi

ARCH="$(detect_arch)"
WORK_DIR="$(mktemp -d "${RUNNER_TEMP}/setup-opentofu.XXXXXXXXXX")"
trap 'rm -rf "${WORK_DIR}"' EXIT

install_tofu "${TOFU_VERSION}" "${ARCH}" "${WORK_DIR}"

if [[ -n "${TERRAMATE_VERSION:-}" ]]; then
  install_terramate "${TERRAMATE_VERSION}" "${ARCH}" "${WORK_DIR}"
fi

echo "Done."
