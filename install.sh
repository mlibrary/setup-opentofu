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

OPENTOFU_GPG_KEY='-----BEGIN PGP PUBLIC KEY BLOCK-----

mQINBGVUyIwBEADPg6jUJm5liMTiDndyprnwXQ23GdyQm/kW9MFOhYDRksmmbsz0
DCfqntFpuoKxPXzA+JTrZlWZONtU+leZjIOlAVZiz0rwz5EJq7uIrkueWtUk6AYk
BLN+zMtbui0z3HCPVNnR5BlVNyXQeW3jlrQtzuKevjZWzI0gbQGgEKNpj+lfyRFu
6q3u/T0o3p/6bOOlQHwCMtnFlWpjr6f/J2EdUVO/6NYHQzImPj4LINXF/+eqo7v6
svFtaVTtREG2V2V7We7bu/cJ+NgJYH7ro7UhB1RQH2k09NdpSCt9F60PVERnORpx
GBkM/VKZzgMSzRvdpxUWwrLxfAxinu5ddbBm3y0bzaU80OT3i1qrWIqW73fmdGHQ
71gbJxRrroyLMWehjcJ/9WJDxkHqsfPKqBifYsp6/J9npczDfSU+zYBVGpR73a4E
dbeIRWqwbH0LWhlbi1IM5aFDaZMFNkY+AWyP+OHn8Kehu6DOIh1AVM7v7vLxaX9h
t1jVJbswjvPFYquv1DvUdc7VP2QHz3xctQS1GZJQ1ekcgTv9rRYXUOOwknInjtkM
9kQDtyBkVLcEc8ha3Cfh6PJscIP5VHwaNMgAPr9tsl3xqdz56l5UPjFSFuel98jS
Bqn83VrT0uKwM0PnDVHd/7q8+Dg1EtOggMwZ830KORFNdjfv6ydsBvl7fwARAQAB
tEpPcGVuVG9mdSAoVGhpcyBrZXkgaXMgdXNlZCB0byBzaWduIG9wZW50b2Z1IHBy
b3ZpZGVycykgPGNvcmVAb3BlbnRvZnUub3JnPokCTAQTAQgAQQUCZVTIjAkQDArz
E+X9n4AWIQTj5uQ9hMuFLq2wBR0MCvMT5f2fgAIbAwIeAQIZAQMLCQcCFQgDFgAC
BScJAgcCAABwAg/1HZnTvPHZDWf5OluYOaQ7ADX/oyjUO85VNUmKhmBZkLr5mTqr
LO72k9fg+101hbggbhtK431z3Ca6ZqDAG/3DBi0BC1ag0rw83TEApkPGYnfX1DWS
1ZvyH1PkV0aqCkXAtMrte2PlUiieaKAsiYOIXqfZwszd07gch14wxMOw1B6Au/Xz
Nrv2omnWSgGIyR6WOsG4QQ8R5AMVz3K8Ftzl6520wBgtr3osA3uM/xconnGVukMn
9NLQqKx5oeaJwONZpyZL5bg2ke9MVZM2+bG30UGZKoxrzOtQ//OTOYlhPCqm1ffR
hYrUytwsWzDnJvXJF1QhnDu8whP3tSrcHyKxYZ9xUNzeu2AmjYfvkKHSdK2DFmOf
DafaRs3c1VYnC7J7aRi6kVF/t+vWeOEVpPylyK7vSbPFc6XVoQrsE07hbN/BjWjm
s8voK5U6oJRgEugXtSQKFypfOq8R99nXwbMHdhqY8aGyOCj++cuvRCUBDZAQqPEW
AuD0X7+9Trnfin47MK+n18wsTAL4w6PJhtCrwK4e0cVuQ5u4M/PMid5W6hEA27PX
x506Jpe8iRmcIP/cCR6pvhgOUMC36bIkAqZ5dJ545kDQju0lf8gLdVIQpig45udn
ZM2KgyApGqhsS7yCUrbLDrtNmQ31TSYdKc8IU+/jXkfy2RYbZ+wNgfloKLkCDQRl
VMiMARAAwRZUyMIc5TNbcFg3WGKxhaNC9hDZ4zBfXlb5jONzZOx3rDi2lD4UQOH+
NpG7CF98co//kryS/4AsDdp2jzhh+VMgyx6KJIhSkBP6kqhriy9eWRmgfrnLbUf4
6kkTkzLVkjYnMNeyHt+mi9I7EKtsDuF/EvjlwF5E81+DEOteCO/un/Qt1q3e1Slf
vTpLkPvr1FiQ3VqzaBeBBI3MAMb/ycwL6hQE1l4Lg34T43Zu+9zkE1uzvjeNIlIW
ucjB4q1htEjJl2CLAv+8cGHdmCcV2ZO3WM8M9Omq1CE7jhak4NE/YuGylJYCBd+B
S7tuDPDu6+o4Nx+axxcwMvgyfr07FteEr1Lopaw2ci8b/xzQie/gkI0CByQMwD5V
gnJpiMBnjP4d6UF6HEVldCQ7a3T1T80bKj5JjtFbR9P85Qntuheqn3Pge89YexMc
E/00VA3blrj+GeYpO9ZGFu7DR/x4sjnTEhfjXEoLv1C4AdgGHCIjW9wU6HkcWnla
X7akKlwIWEUP/BFLkcWPpmUrtClhWx9wq1GHFvKAN/qp//VWnv4IfRU6RjmVPOWB
efvTu/cpsfBHLyp15goOYPboahIdTUTNQIXh4Vid7E1NoKnWZUMu50n3/zAbjSds
mNmifi4g01MYJ3TVoU2Q01P7NiD3IRmaw72nLmf9cM9/7QMdGn0AEQEAAYkCNgQY
AQgAKgUCZVTIjAkQDArzE+X9n4AWIQTj5uQ9hMuFLq2wBR0MCvMT5f2fgAIbDAAA
SUoP/2ExsUoGbxjuZ76QUnYtfzDoz+o218UWd3gZCsBQ6/hGam5kMq+EUEabF3lV
7QLDyn/1v5sqrkmYg0u5cfjtY3oimCPvr6E0WTuqMIwYl0fdlkmdNttDpMqvCazq
bzLK5dDVWbh/EYTiEN1xKXM6rlAquYv8I16uWL8QHanMb6yexNmDYhC4fXWqCi+s
5sXxWrPrd+fGz8CR/fEYahPXj8uY6dwN9DlWyek9QtKW2PsqrkBn5vCOm2IyZW6d
t/Kn70tYtxMxJND2otk47mpG/Fv3sYK2bTGJ+k/5+E5IrjWqIX2lVB3G1+TCoZ5s
cc16zls32mOlRh81fTAqcwkDFxICxcOeNHGLt3N+UvoPSUafYKD96rn5mWFao4xb
cFniaYv2PdqH8HDjvXZXqHypRMXvYMbXXOgydLL+tSUSBpMTd4afjq8x2gNSWOEL
I1jT5FWbKTKan0ycKi37bSqGHhDjlg4HRGvC3IK0EuVjdX3r+8uIVgFbqLwNhXk4
GAIL03vl689TQ7/oPW75XCQIevFai0kcJPl6qIRvi9/S/v5EPRy9UDCGY/MPmc5f
H1an0ebU4I4TlYfBoEUkYYqBDxvxWW0I/Q01rDebcd6mrGw8lW1EiNZlClLwx9Bv
/+MNnIT9m1f8KeqmweoAgbIQRUI7EkJSzxYN4DNuy2XoKmF9
=CRuR
-----END PGP PUBLIC KEY BLOCK-----'

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
  echo "${OPENTOFU_GPG_KEY}" | gpg --homedir "${gnupghome}" --import 2>/dev/null
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
