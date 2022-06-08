#!/bin/bash

set -euxo pipefail

# cd nixpkgs
# git bisect start '--no-checkout'
# # bad: [3586c258e8dfd305b8a6c65dd5c98efabd288e59] haskell.packages.ghc923: pin fourmolu to 0.6.0.0
# git bisect bad 3586c258e8dfd305b8a6c65dd5c98efabd288e59
# # good: [21a3136d25e1652cb32197445e9799e6a5154588] haskellPackages.happy_1_19_12: Disable tests
# git bisect good 21a3136d25e1652cb32197445e9799e6a5154588

e_skip() { exit 125; }
e_good() { exit 0; }
e_bad() { exit 1; }
e_abort() { exit 130; }

bisect_head="$(git rev-parse BISECT_HEAD)"

(
  cd -- "$(dirname -- "$0")"
  # 1. try to eval. any errors, skip.
  # because sometimes (eg github:NixOS/nixpkgs/fa7a0dbb826#haskell.packages.ghcjs.ghcjs-base) things just fail to eval.
  if ! nix show-derivation '.#ghcjs-base' --override-input nixpkgs "github:NixOS/nixpkgs/$bisect_head" >/dev/null; then
    e_skip
  fi
  # 2. try to dry-build. too many packages not avail in cache, skip.
  output="$(nix build --dry-run '.#ghcjs-base' --override-input nixpkgs "github:NixOS/nixpkgs/$bisect_head" 2>&1)" || e_abort
  howmany="$(echo "$output" | grep -P '^these [0-9]+ derivations will be built:$' | grep -oP '\b[0-9]+\b')" || true
  if [[ "$howmany" ]]; then
    if (( howmany > 100 )); then e_skip; fi
  else
    : # guess we already built it...? ok
  fi
  # 2.5. TODO check free space
  # 3. try to build.
  # if it hangs, kill it yourself
  if nix build '.#ghcjs-base' --no-link --override-input nixpkgs "github:NixOS/nixpkgs/$bisect_head"; then
    e_good
  else
    e_bad
  fi
  e_abort
)
exit
