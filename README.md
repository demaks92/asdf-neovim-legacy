# asdf-neovim-legacy

[![Build](https://github.com/demaks92/asdf-neovim-legacy/workflows/Build/badge.svg)](https://github.com/demaks92/asdf-neovim-legacy/actions/workflows/build.yml)
[![Lint](https://github.com/demaks92/asdf-neovim-legacy/workflows/Lint/badge.svg)](https://github.com/demaks92/asdf-neovim-legacy/actions/workflows/lint.yml)

[Neovim](https://neovim.io/) plugin for the [asdf](https://asdf-vm.com/) version manager.

## Contents

- [Dependencies](#dependencies)
- [Install](#install)
- [Use](#use)
- [License](#license)

## Dependencies

- `bash`, `curl`, `git`, `tar`.
- Optionally `sha256sum` or `shasum` for checksum verification.

## Install

Plugin:

```shell
asdf plugin add neovim-legacy <this-repository-url>
```

Neovim:

```shell
# Show all installable versions
asdf list all neovim-legacy

# Install a specific release from neovim/neovim-releases
asdf install neovim-legacy 0.12.2

# Install the upstream stable tag
asdf install neovim-legacy stable

# Set a version globally
asdf set -u neovim-legacy 0.12.2

# Now nvim commands are available
nvim --version
```

This plugin installs prebuilt release archives from [neovim/neovim-releases](https://github.com/neovim/neovim-releases). Installation from source, branches, commits, and nightly builds are not supported.

Upstream distributes `nvim-linux-x86_64.tar.gz` exclusively, therefore this plugin provides Linux-x86_64 installation support only.

Check [asdf](https://github.com/asdf-vm/asdf) readme for more instructions on how
to install and manage versions.

## Use

This plugin is designed to install Neovim on older operating systems with GLIBC version <2.18
For other environments, consider using [asdf-neovim](https://github.com/richin13/asdf-neovim)

## License

See [LICENSE](LICENSE).
