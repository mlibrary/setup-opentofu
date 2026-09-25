#!/bin/bash
set -euo pipefail

source "${GH_ACTION_PATH}/lib.sh"

install_tofu() {
  local ver="$1"
  local os="$2"
  local arch="$3"
  local dir="$4"
  local work="$5"
  local tgz="tofu_${ver}_${os}_${arch}.tar.gz"
  local sums="tofu_${ver}_SHA256SUMS"
  local sig="tofu_${ver}_SHA256SUMS.sig"
  local cert="tofu_${ver}_SHA256SUMS.pem"
  local base_url="https://github.com/opentofu/opentofu/releases/download/v${ver}"
  # OpenTofu release workflows run from a release branch named after the
  # version's major.minor (e.g. v1.12), and sign SHA256SUMS keylessly via
  # GitHub Actions OIDC.
  local major_minor="${ver%.*}"
  local cert_identity_regexp="^https://github\\.com/opentofu/opentofu/\\.github/workflows/release\\.yml@refs/heads/v${major_minor}$"

  echo "Downloading OpenTofu ${ver} (${os}/${arch})..."
  curl -fsSL -o "${work}/${tgz}"  "${base_url}/${tgz}"
  curl -fsSL -o "${work}/${sums}" "${base_url}/${sums}"
  curl -fsSL -o "${work}/${sig}"  "${base_url}/${sig}"
  curl -fsSL -o "${work}/${cert}" "${base_url}/${cert}"

  echo "Verifying OpenTofu cosign signature..."
  cosign verify-blob \
    --certificate "${work}/${cert}" \
    --signature "${work}/${sig}" \
    --certificate-identity-regexp "${cert_identity_regexp}" \
    --certificate-oidc-issuer https://token.actions.githubusercontent.com \
    "${work}/${sums}" \
    || onoe "OpenTofu cosign signature verification failed"

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
  local os="$2"
  local arch="$3"
  local dir="$4"
  local work="$5"
  local tgz="terramate_${ver}_${os}_${arch}.tar.gz"
  local sums="checksums.txt"
  local sig="checksums.txt.sig"
  local pub="cosign.pub"
  local base_url="https://github.com/terramate-io/terramate/releases/download/v${ver}"

  echo "${TERRAMATE_COSIGN_PUB}" > "${work}/${pub}"

  echo "Downloading Terramate ${ver} (${os}/${arch})..."
  curl -fsSL -o "${work}/${tgz}"  "${base_url}/${tgz}"
  curl -fsSL -o "${work}/${sums}" "${base_url}/${sums}"
  curl -fsSL -o "${work}/${sig}"  "${base_url}/${sig}"

  echo "Verifying Terramate cosign signature..."
  cosign verify-blob \
    --key "${work}/${pub}" \
    --signature "${work}/${sig}" \
    "${work}/${sums}" \
    || onoe "Terramate cosign signature verification failed"

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
[[ -n "${OS:-}" ]] || onoe "OS is not set."
[[ -n "${ARCH:-}" ]] || onoe "ARCH is not set."

WORK_DIR="$(mktemp -d "${RUNNER_TEMP}/setup-opentofu.XXXXXXXXXX")"
trap 'rm -rf "${WORK_DIR}"' EXIT

if [[ "${TOFU_CACHE_HIT:-}" == "true" ]]; then
  echo "Using cached OpenTofu ${TOFU_VERSION} (${OS}/${ARCH})."
else
  install_tofu "${TOFU_VERSION}" "${OS}" "${ARCH}" "${TOFU_DIR}" "${WORK_DIR}"
fi

if [[ -n "${TERRAMATE_VERSION:-}" ]]; then
  [[ -n "${TERRAMATE_DIR:-}" ]] || onoe "TERRAMATE_DIR is not set."
  # Terramate's tar.gz releases use x86_64 rather than amd64 in their file names.
  case "${ARCH}" in
    amd64) TERRAMATE_ARCH="x86_64" ;;
    *) TERRAMATE_ARCH="${ARCH}" ;;
  esac
  if [[ "${TERRAMATE_CACHE_HIT:-}" == "true" ]]; then
    echo "Using cached Terramate ${TERRAMATE_VERSION} (${OS}/${ARCH})."
  else
    install_terramate "${TERRAMATE_VERSION}" "${OS}" "${TERRAMATE_ARCH}" "${TERRAMATE_DIR}" "${WORK_DIR}"
  fi
fi

echo "Done."
