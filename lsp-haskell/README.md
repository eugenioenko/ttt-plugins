# lsp-haskell

Auto-configures `haskell-language-server` (HLS) as the Haskell language server for ttt.

## Requirements

HLS needs a matching GHC on your `PATH`. The recommended way to install both is [GHCup](https://www.haskell.org/ghcup/):

```sh
curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh
ghcup install ghc --set recommended
ghcup install cabal --set recommended
ghcup install hls --set recommended
```

On Debian/Ubuntu, GHCup needs these system packages first:

```sh
sudo apt install build-essential curl libffi-dev libgmp-dev libgmp10 libncurses-dev pkg-config xz-utils
```

Make sure `~/.ghcup/bin` is on your `PATH`, then verify:

```sh
haskell-language-server-wrapper --version
```

The wrapper picks the HLS binary that matches your project's GHC version. If HLS reports your GHC as unsupported, install a GHC version HLS supports with `ghcup tui`.

Other install options (Homebrew, Nix, distro packages) are listed in the [HLS installation docs](https://haskell-language-server.readthedocs.io/en/latest/installation.html).

## What it does

When installed, this plugin sets `lsp.servers.haskell` in your settings to enable LSP features (autocomplete, hover, diagnostics) for `.hs` and `.lhs` files.

When uninstalled, the setting is automatically removed.
