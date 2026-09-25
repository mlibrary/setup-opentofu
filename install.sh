#!/bin/bash
set -euo pipefail

source "${GH_ACTION_PATH}/lib.sh"

install_tofu() {
  local ver="$1"
  local arch="$2"
  local dir="$3"
  local work="$4"
  local tgz="tofu_${ver}_linux_${arch}.tar.gz"
  local sums="tofu_${ver}_SHA256SUMS"
  local gpgsig="tofu_${ver}_SHA256SUMS.gpgsig"
  local base_url="https://github.com/opentofu/opentofu/releases/download/v${ver}"

  echo "Downloading OpenTofu ${ver} (${arch})..."
  curl -fsSL -o "${work}/${tgz}"    "${base_url}/${tgz}"
  curl -fsSL -o "${work}/${sums}"   "${base_url}/${sums}"
  curl -fsSL -o "${work}/${gpgsig}" "${base_url}/${gpgsig}"

  echo "Verifying OpenTofu GPG signature..."
  local gnupghome
  gnupghome="$(mktemp -d)"
  gpg --homedir "${gnupghome}" --import "${GH_ACTION_PATH}/opentofu.gpg" 2>/dev/null
  gpg --homedir "${gnupghome}" --verify "${work}/${gpgsig}" "${work}/${sums}" \
    || onoe "OpenTofu GPG signature verification failed"
  rm -rf "${gnupghome}"

  echo "Verifying OpenTofu checksum..."
  (cd "${work}" && grep "${tgz}" "${sums}" | sha256sum --check --status) \
    || onoe "OpenTofu checksum verification failed"

  echo "Installing OpenTofu to ${dir}..."
  mkdir -p "${dir}"
  tar -xzf "${work}/${tgz}" -C "${dir}" tofu
  chmod +x "${dir}/tofu"
}

TERRAMATE_COSIGN_PUB='-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAETPWlyfCSXqmaw8dZv3nlqiQ/hPKw
I5KPGKOaYzzYII4Vk6BzG0tvW7LgeEbR7js4lDCv0yMRHtrDe7h1D1ymHg==
-----END PUBLIC KEY-----'

install_terramate() {
  local ver="$1"
  local arch="$2"
  local dir="$3"
  local work="$4"
  local tgz="terramate_${ver}_linux_${arch}.tar.gz"
  local sums="checksums.txt"
  local sig="checksums.txt.sig"
  local pub="cosign.pub"
  local base_url="https://github.com/terramate-io/terramate/releases/download/v${ver}"

  echo "${TERRAMATE_COSIGN_PUB}" > "${work}/${pub}"

  echo "Downloading Terramate ${ver} (${arch})..."
  curl -fsSL -o "${work}/${tgz}"  "${base_url}/${tgz}"
  curl -fsSL -o "${work}/${sums}" "${base_url}/${sums}"
  curl -fsSL -o "${work}/${sig}"  "${base_url}/${sig}"

  echo "Verifying Terramate signature..."
  base64 -d "${work}/${sig}" > "${work}/checksums.txt.sig.bin" \
    || onoe "Failed to decode Terramate signature file"
  openssl dgst -sha256 -verify "${work}/${pub}" -signature "${work}/checksums.txt.sig.bin" "${work}/${sums}" \
    || onoe "Terramate signature verification failed"

  echo "Verifying Terramate checksum..."
  (cd "${work}" && grep "${tgz}" "${sums}" | sha256sum --check --status) \
    || onoe "Terramate checksum verification failed"

  echo "Installing Terramate to ${dir}..."
  mkdir -p "${dir}"
  tar -xzf "${work}/${tgz}" -C "${dir}" terramate
  chmod +x "${dir}/terramate"
}

[[ -n "${TOFU_VERSION:-}" ]] || onoe "TOFU_VERSION is not set."
[[ -n "${TOFU_DIR:-}" ]] || onoe "TOFU_DIR is not set."
[[ -n "${ARCH:-}" ]] || onoe "ARCH is not set."

WORK_DIR="$(mktemp -d "${RUNNER_TEMP}/setup-opentofu.XXXXXXXXXX")"
trap 'rm -rf "${WORK_DIR}"' EXIT

if [[ "${TOFU_CACHE_HIT:-}" == "true" ]]; then
  echo "Using cached OpenTofu ${TOFU_VERSION} (${ARCH})."
else
  install_tofu "${TOFU_VERSION}" "${ARCH}" "${TOFU_DIR}" "${WORK_DIR}"
fi

if [[ -n "${TERRAMATE_VERSION:-}" ]]; then
  [[ -n "${TERRAMATE_DIR:-}" ]] || onoe "TERRAMATE_DIR is not set."
  # Terramate's tar.gz releases use x86_64 rather than amd64 in their file names.
  case "${ARCH}" in
    amd64) TERRAMATE_ARCH="x86_64" ;;
    *) TERRAMATE_ARCH="${ARCH}" ;;
  esac
  if [[ "${TERRAMATE_CACHE_HIT:-}" == "true" ]]; then
    echo "Using cached Terramate ${TERRAMATE_VERSION} (${ARCH})."
  else
    install_terramate "${TERRAMATE_VERSION}" "${TERRAMATE_ARCH}" "${TERRAMATE_DIR}" "${WORK_DIR}"
  fi
fi

echo "Done."
