# GitHub Action for setting up OpenTofu

Installs OpenTofu, and optionally Terramate, from GitHub releases.
- Performs cosign signature verification for both tofu and terramate.
- Depends on [actions/cache](https://github.com/actions/cache) (to cache downloaded binaries across runs) and [sigstore/cosign-installer](https://github.com/sigstore/cosign-installer) (to install cosign for signature verification).
- Written in bash. Very short. Simplicity (and thus transparency) over features.
- Tested on `ubuntu-24.04`, `ubuntu-24.04-arm`, `ubuntu-26.04`, and `macos-latest`.

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
Downloads and verifies checksums and signatures before install, using [cosign](https://github.com/sigstore/cosign) (installed via [sigstore/cosign-installer](https://github.com/sigstore/cosign-installer)) for both tools.

Terramate is signed with a static cosign key. This key is embedded in `install.sh` as the trust anchor; it was downloaded from the [terramate release page](https://github.com/terramate-io/terramate/releases), where it can be found attached to each release as `cosign.pub`.

OpenTofu is signed keylessly, using cosign's GitHub Actions OIDC identity. Verification pins the expected certificate identity (OpenTofu's `release.yml` workflow, on the release's `refs/heads/v<major>.<minor>` branch) and OIDC issuer (`https://token.actions.githubusercontent.com`), so trust doesn't depend on distributing or rotating a key.

### Install
This action downloads the `.tar.gz` release archives (rather than `.deb` packages), extracts the binaries, and installs them to `$RUNNER_TOOL_CACHE/<tool>/<version>/<os>-<arch>` (falling back to `~/.cache/setup-opentofu-tool-cache` if `RUNNER_TOOL_CACHE` isn't set), following the same convention used by `actions/toolkit`'s tool-cache. That directory is then added to `$PATH` via `$GITHUB_PATH`, so `tofu`/`terramate` are available to subsequent steps without root/sudo access.

### Caching
[actions/cache](https://github.com/actions/cache) is used to cache each tool's install directory, keyed on OS, architecture, and version, so repeat runs with the same versions skip the download/verify/extract steps entirely.
