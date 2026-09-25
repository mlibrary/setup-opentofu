#!/bin/bash
# Resolves and validates tofu/terramate versions and computes the install
# directories used for actions/cache and installation. Emits step outputs.
set -euo pipefail

source "${GH_ACTION_PATH}/lib.sh"

if [[ -n "${TOFU_VERSION_FILE:-}" ]]; then
  TOFU_VERSION="$(read_version_file "tofu_version_file" "${TOFU_VERSION_FILE}")"
fi
if [[ -z "${TOFU_VERSION:-}" ]]; then
  onoe "Either tofu_version or tofu_version_file must be provided."
fi
validate_version "tofu_version" "${TOFU_VERSION}"

if [[ -n "${TERRAMATE_VERSION_FILE:-}" ]]; then
  TERRAMATE_VERSION="$(read_version_file "terramate_version_file" "${TERRAMATE_VERSION_FILE}")"
fi
if [[ -n "${TERRAMATE_VERSION:-}" ]]; then
  validate_version "terramate_version" "${TERRAMATE_VERSION}"
fi

resolve_arch

# Follow GitHub Actions tool-cache conventions (as used by actions/toolkit's
# tool-cache + core.addPath): <tool cache root>/<tool>/<version>/<arch>.
TOOL_CACHE_ROOT="${RUNNER_TOOL_CACHE:-${HOME}/.cache/setup-opentofu-tool-cache}"
TOFU_DIR="${TOOL_CACHE_ROOT}/tofu/${TOFU_VERSION}/${ARCH}"

{
  echo "tofu_version=${TOFU_VERSION}"
  echo "arch=${ARCH}"
  echo "tofu_dir=${TOFU_DIR}"
} >> "${GITHUB_OUTPUT}"

if [[ -n "${TERRAMATE_VERSION:-}" ]]; then
  TERRAMATE_DIR="${TOOL_CACHE_ROOT}/terramate/${TERRAMATE_VERSION}/${ARCH}"
  {
    echo "terramate_version=${TERRAMATE_VERSION}"
    echo "terramate_dir=${TERRAMATE_DIR}"
  } >> "${GITHUB_OUTPUT}"
fi
