# itah's NixOS configuration

Dendritic NixOS + Home Manager configuration for the `nixos` host.

## Layout

```text
flake.nix                    flake-parts entry point
flake.lock                   pinned inputs
modules/
├── features/                self-registering features
├── hosts/nixos/             host composition + hardware
├── infrastructure/          flake plumbing, Home Manager base, checks
├── btop/                    raw app config files
├── fastfetch/
├── gtk/
├── kitty/
└── umbriel/
scripts/                     helper scripts
```

## How features work

Every `.nix` file under `modules/` is imported by `import-tree`. A feature
registers itself instead of being added to a central list.

NixOS feature:

```nix
_: {
  flake.modules.nixos.foo = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.foo ];
  };
}
```

Home Manager feature:

```nix
_: {
  flake.modules.homeManager.foo = { pkgs, ... }: {
    home.packages = [ pkgs.foo ];
  };
}
```

The host imports every `flake.modules.nixos.*` module, and the Home Manager
base imports every `flake.modules.homeManager.*` module. Adding a new feature
file is enough to enable it.

Raw config files belong in `modules/<app>/` and are referenced from the
matching feature module.

## Common commands

| Command | Purpose |
| --- | --- |
| `nrs` | `nh os switch ~/Nixos` |
| `nrb` | `nh os boot ~/Nixos` |
| `nrt` | `nh os test ~/Nixos` |
| `nru` | `nh os switch ~/Nixos --refresh` |
| `nrr` | `nh os rollback` |
| `nfu` | `cd ~/Nixos && nix flake update` |
| `nrd` | dry-build with `nh os switch ~/Nixos -n` |
| `ndiff` | diff current system against `./result` |
| `ngc` | `nh clean all --optimise` |

The aliases come from `modules/features/shell.nix` and work in both bash and
fish.

## Validation

```bash
nix flake check
nixos-rebuild dry-build --flake ~/Nixos#nixos
nix fmt
nix develop
```

`nix flake check` runs `statix`, `deadnix`, `nixfmt`, and evaluates/builds the
NixOS toplevel. `nix develop` provides the same linting tools.

## Auto-update

`modules/features/auto-update.nix` enables a weekly `system.autoUpgrade` that:

- updates `nixpkgs`, `home-manager`, `flake-parts`, and `import-tree`;
- rebuilds `/home/itah/Nixos` with `nixos-rebuild switch`;
- does not reboot automatically;
- updates `flake.lock` in place but does not commit it;
- chowns `flake.lock` back to `itah:users` after the run.

Check logs with:

```bash
journalctl -u nixos-upgrade
```

Roll back with `nrr` if an unattended update causes problems.

## Notes

- `features/nvim.nix` clones the AstroNvim template on first activation. It is
  intentionally mutable so you can edit the Neovim config normally.
- `kitty`, `btop`, `fastfetch`, and `umbriel` use activation copies so their
  configs stay writable. Noctalia also writes theme files at runtime.
- Auto-importing every module is ideal for this single-host setup. If a second
  host is added with a different feature set, switch the host to explicit
  per-host module lists.
