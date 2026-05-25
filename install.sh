#!/bin/bash
set -euo pipefail

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

install_tofu() {
  local ver="$1"
  local arch="$2"
  local dir="$3"
  local deb="tofu_${ver}_${arch}.deb"
  local sums="tofu_${ver}_SHA256SUMS"
  local gpgsig="tofu_${ver}_SHA256SUMS.gpgsig"
  local base_url="https://github.com/opentofu/opentofu/releases/download/v${ver}"

  echo "Downloading OpenTofu ${ver} (${arch})..."
  curl -fsSL -o "${dir}/${deb}"    "${base_url}/${deb}"
  curl -fsSL -o "${dir}/${sums}"   "${base_url}/${sums}"
  curl -fsSL -o "${dir}/${gpgsig}" "${base_url}/${gpgsig}"

  echo "Verifying OpenTofu GPG signature..."
  local gnupghome
  gnupghome="$(mktemp -d)"
  gpg --homedir "${gnupghome}" --import "${BASH_SOURCE[0]%/*}/opentofu.gpg" 2>/dev/null
  gpg --homedir "${gnupghome}" --verify "${dir}/${gpgsig}" "${dir}/${sums}" \
    || onoe "OpenTofu GPG signature verification failed"
  rm -rf "${gnupghome}"

  echo "Verifying OpenTofu checksum..."
  (cd "${dir}" && grep "${deb}" "${sums}" | sha256sum --check --status) \
    || onoe "OpenTofu checksum verification failed"

  echo "Installing OpenTofu..."
  sudo dpkg -i "${dir}/${deb}"
}

TERRAMATE_COSIGN_PUB='-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAETPWlyfCSXqmaw8dZv3nlqiQ/hPKw
I5KPGKOaYzzYII4Vk6BzG0tvW7LgeEbR7js4lDCv0yMRHtrDe7h1D1ymHg==
-----END PUBLIC KEY-----'

install_terramate() {
  local ver="$1"
  local arch="$2"
  local dir="$3"
  local deb="terramate_${ver}_linux_${arch}.deb"
  local sums="checksums.txt"
  local sig="checksums.txt.sig"
  local pub="cosign.pub"
  local base_url="https://github.com/terramate-io/terramate/releases/download/v${ver}"

  echo "${TERRAMATE_COSIGN_PUB}" > "${dir}/${pub}"

  echo "Downloading Terramate ${ver} (${arch})..."
  curl -fsSL -o "${dir}/${deb}"  "${base_url}/${deb}"
  curl -fsSL -o "${dir}/${sums}" "${base_url}/${sums}"
  curl -fsSL -o "${dir}/${sig}"  "${base_url}/${sig}"

  echo "Verifying Terramate signature..."
  base64 -d "${dir}/${sig}" > "${dir}/checksums.txt.sig.bin" \
    || onoe "Failed to decode Terramate signature file"
  openssl dgst -sha256 -verify "${dir}/${pub}" -signature "${dir}/checksums.txt.sig.bin" "${dir}/${sums}" \
    || onoe "Terramate signature verification failed"

  echo "Verifying Terramate checksum..."
  (cd "${dir}" && grep "${deb}" "${sums}" | sha256sum --check --status) \
    || onoe "Terramate checksum verification failed"

  echo "Installing Terramate..."
  sudo dpkg -i "${dir}/${deb}"
}

validate_version "tofu_version" "${TOFU_VERSION}"
if [[ -n "${TERRAMATE_VERSION:-}" ]]; then
  validate_version "terramate_version" "${TERRAMATE_VERSION}"
fi

case "${MACHTYPE}" in
  x86_64*)  ARCH="amd64" ;;
  aarch64*) ARCH="arm64" ;;
  *) onoe "Unsupported architecture: ${MACHTYPE}" ;;
esac
WORK_DIR="$(mktemp -d "${RUNNER_TEMP}/setup-opentofu.XXXXXXXXXX")"
trap 'rm -rf "${WORK_DIR}"' EXIT

install_tofu "${TOFU_VERSION}" "${ARCH}" "${WORK_DIR}"

if [[ -n "${TERRAMATE_VERSION:-}" ]]; then
  install_terramate "${TERRAMATE_VERSION}" "${ARCH}" "${WORK_DIR}"
fi

echo "Done."
