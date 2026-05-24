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

