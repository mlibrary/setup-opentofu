# GitHub Action for setting up OpenTofu

Installs OpenTofu, and optionally Terramate, from GitHub releases.
- Performs signature verification for both tofu and terramate.
- Zero recursive dependencies on other actions.
- Written in bash. Very short. Simplicity (and thus transparency) over features.
- Tested on `ubuntu-24.04` and `ubuntu-24.04-arm`. Linux only. Debian based distros only (requires dpkg).

## Usage
```
steps:
- uses: mlibrary/setup-opentofu
  with:
    tofu_version: 1.12.0       # required
    terramate_version: 0.17.0  # optional, only needed if you want to install Terramate
    allow_prerelease: false    # optional, set to true to allow prerelease versions (e.g. 1.8.0-rc1)
```

## Internals

### Package Verification
Downloads and verifies checksums and signatures before install.

Terramate is signed only with [cosign](https://github.com/sigstore/cosign). Because it uses a static key we are able to use OpenSSL to handle verification.

OpenTofu is signed w/ both gpg and cosign. However, it uses OIDC it can't be trivially verified without cosign installed, so we verify gpg signature.

To establish trust anchors, both pub keys are embedded in this action:
- OpenTofu key: `opentofu.gpg`, can be replicated with `curl -fs https://get.opentofu.org/opentofu.gpg | sq packet armor > opentofu.gpg` (or use `gpg --enarmor`, if you must).
- Terramate key is directly embedded in `install.sh`. This signature was downloaded from the [terramate release page](https://github.com/terramate-io/terramate/releases), where it can be found attached to each release as `cosign.pub`.

### Install
This action installs `.deb` packages, so works only Debian based systems (Debian, Ubuntu, etc).

## Roadmap
We're not using [sigstore/cosign-installer](https://github.com/sigstore/cosign-installer), because that would add an action dependency. [Cosign is in Ubuntu 26.04](https://packages.ubuntu.com/resolute/cosign), so we'll likely switch to using the Ubuntu package, and switch to using the OpenTofu cosign signatures sometime after GitHub supports runners on 26.04. If this happens it will be a new major release, and will drop all support for 24.04.
