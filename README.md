# GitHub Action for setting up OpenTofu

Installs OpenTofu, and optionally Terramate, from GitHub releases. 

This action is tested on `ubuntu-24.04` and `ubuntu-24.04-arm`.

It may work on Debian as well, but this is not tested. It will not work on macOS runners.

## Usage
```
steps:
- uses: mlibrary/setup-opentofu
  with:
    tofu_version: 1.12.0       # required
    terramate_version: 0.17.0  # optional, only needed if you want to install Terramate
    allow_prerelease: false    # optional, set to true to allow prerelease versions (e.g. 1.8.0-rc1)
```

## OpenTofu signing key

Each OpenTofu release is GPG-signed. The armored public key is embedded in
`install.sh` as `OPENTOFU_GPG_KEY` so that no network request is needed to
establish a trust anchor.

**Key details**
- Key ID: `0C0AF313E5FD9F80`
- Fingerprint: `E3E6 E43D 84CB 852E ADB0  051D 0C0A F313 E5FD 9F80`
- UID: `OpenTofu (This key is used to sign opentofu providers) <core@opentofu.org>`

**Fetching and verifying the key**

To fetch the key yourself and confirm it matches the embedded copy:

```bash
curl -fsSL \
  "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xE3E6E43D84CB852EADB0051D0C0AF313E5FD9F80" \
  -o opentofu.asc
gpg --import opentofu.asc
gpg --fingerprint E3E6E43D84CB852EADB0051D0C0AF313E5FD9F80
```

The expected fingerprint is `E3E6 E43D 84CB 852E ADB0  051D 0C0A F313 E5FD 9F80`.
If OpenTofu ever rotates their key, update `OPENTOFU_GPG_KEY` in `install.sh`
with the output of `gpg --armor --export <new-fingerprint>`.

