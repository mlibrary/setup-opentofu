# GitHub Action for setting up OpenTofu

Installs OpenTofu, and optionally Terramate, from GitHub releases.
- Performs signature verification for both tofu and terramate.
- Only dependency on another action is [actions/cache](https://github.com/actions/cache), used to cache downloaded binaries across runs.
- Written in bash. Very short. Simplicity (and thus transparency) over features.
- Tested on `ubuntu-24.04` and `ubuntu-24.04-arm`. Linux only.

## Usage
```
steps:
- uses: mlibrary/setup-opentofu
  with:
    tofu_version: 1.12.0            # required unless tofu_version_file is set
    tofu_version_file: .opentofu-version # optional, takes precedence over tofu_version
    terramate_version: 0.17.0       # optional, only needed if you want to install Terramate
    terramate_version_file: .terramate-version # optional, takes precedence over terramate_version
    allow_prerelease: false         # optional, set to true to allow prerelease versions (e.g. 1.8.0-rc1)
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
This action downloads the `.tar.gz` release archives (rather than `.deb` packages), extracts the binaries, and installs them to `$RUNNER_TOOL_CACHE/<tool>/<version>/<arch>` (falling back to `~/.cache/setup-opentofu-tool-cache` if `RUNNER_TOOL_CACHE` isn't set), following the same convention used by `actions/toolkit`'s tool-cache. That directory is then added to `$PATH` via `$GITHUB_PATH`, so `tofu`/`terramate` are available to subsequent steps without root/sudo access.

### Caching
[actions/cache](https://github.com/actions/cache) is used to cache each tool's install directory, keyed on OS, architecture, and version, so repeat runs with the same versions skip the download/verify/extract steps entirely.

## Roadmap
We're not using [sigstore/cosign-installer](https://github.com/sigstore/cosign-installer), because that would add another action dependency. [Cosign is in Ubuntu 26.04](https://packages.ubuntu.com/resolute/cosign), so we'll likely switch to using the Ubuntu package, and switch to using the OpenTofu cosign signatures sometime after GitHub supports runners on 26.04. If this happens it will be a new major release, and will drop all support for 24.04.
