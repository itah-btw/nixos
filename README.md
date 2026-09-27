# nixos

Two NixOS hosts and one Home Manager, as a [dendritic][dendritic] flake.

| Host | Session | Role |
| --- | --- | --- |
| `hp` | Umbriel + Noctalia Shell, Noctalia Greeter | Laptop: desktop, mail, development |
| `tv` | Plasma Big Screen, SDDM autologin | Appliance: Stremio, Nuvio, local media on `/mnt/media` |

[dendritic]: https://github.com/nix-community/flake-parts/wiki/Dendritic-Pattern

## Layout

```
flake.nix                 inputs + the entry point; no logic
hardware-configuration*.nix   generated, never hand-edited
modules/
  options.nix             flake-private plumbing (wiring table, constants)
  formatter.nix           `nix fmt` (nixfmt) and `nix run .#lint` (deadnix + statix)
  checks.nix              policy guards, run by `nix flake check`
  <feature>.nix           one feature, named after what it configures
  hosts/hp.nix            composition point for hp
  hosts/tv.nix            composition point for tv
```

## Conventions

**The filename is the module name.** `modules/nix.nix` defines
`flake.nixosModules.nix`. There are no layer folders (`core/`, `home/`, `tv/`)
because the layer is expressed by the namespace, not the directory — a feature
like `mariadb.nix` legitimately owns both `nixosModules.mariadb` and
`homeManagerModules.mariadb`, and one file says so honestly. The `tv-` prefix
on the tv host's modules is load-bearing for the same reason: the directory no
longer namespaces, so the name has to.

**A module file declares one feature and nothing else.** Cross-references go in
comments ("xkb lives in locale.nix"), never in imports. The only path imports
in the flake are the two generated `hardware-configuration*.nix` files.

**Hosts are the only place that composes.** `modules/hosts/*.nix` declares which
modules each host gets in `flake.hostModules.<host>`, and builds its
`modules` list from that same declaration:

```nix
flake.hostModules.hp = { nixos = [ "boot" "locale" ... ]; home = [ "apps" ... ]; };
...
] ++ map (n: config.flake.nixosModules.${n}) config.flake.hostModules.hp.nixos
```

Because the declaration *is* the wiring, `checks.nix` can assert it against the
modules that exist. That catches the one failure mode a dendritic import cannot
catch by itself: a file that evaluates fine and is never used.

## Shared values

`flake.constants` (in `options.nix`) holds the scalars more than one module
needs — the username, the flake path, the timezone and locale, the keyboard
layout, the tv's address. Modules read them from their own function arguments,
threaded in by the host through `specialArgs` and `extraSpecialArgs`, because
neither the NixOS nor the Home Manager module system can see `config.flake.*`
from inside a module. `checks.nix` asserts the key set, so a typo fails the
build instead of quietly evaluating to `""`.

Note that module arguments belong on the *inner* module, not the flake-parts
wrapper — flake-parts does not provide `constants`:

```nix
# right
{ flake.nixosModules.locale = { constants, ... }: { ... }; }

# wrong: `constants` is unprovided at the flake-parts level
{ constants, ... }: { flake.nixosModules.locale = { ... }; }
```

## Commands

| Command | What it does |
| --- | --- |
| `nix fmt` | nixfmt only. Safe to run implicitly; `push` does it for you. |
| `nix run .#lint` | deadnix + statix, **check-only** — reports, never rewrites. |
| `nix flake check` | treefmt check plus the policy guards. |
| `rb` / `dry` / `nsu` / `ntest` | rebuild, dry build, switch+update, test. |
| `deploy-tv` | build the tv closure here, copy it over the LAN, then activate. |

`nix fmt` deliberately does *not* run deadnix or statix. They are fixers, and
leaving them in the formatter meant `push` swept unrelated auto-fixes from other
modules into whatever you happened to be committing.

## Policy guards

`checks.nix` builds a single derivation that runs every rule as a jq predicate
over one JSON description of the flake, so one `nix flake check` reports every
failure at once. Rules are written as `all(.[]; ...)` over the per-host facts
rather than repeated per host: a rule for a feature only one host has is
vacuous on the other, and a vacuous check still costs a build while reading as
if it were protecting something.

Current rules: `modules-wired`, `dual-namespace-wired`, `constants-intact`,
`host-identity`, `single-dm`, `greeter-implies-greetd`, `no-tts`, `no-x-server`,
`firewall`, `auto-gc`, `binary-cache`, `mariadb-loopback`,
`noctalia-theming-runtime`, `noctalia-single-launcher`, `starship-unmanaged`.

The last three encode decisions that are easy to break by accident and hard to
notice when broken: Noctalia's theme, wallpaper and palettes must stay
runtime-managed (setting them in Home Manager stops wallpaper-derived palettes
and rotation), Noctalia must be started by Umbriel and not also by systemd, and
`starship.toml` must stay Noctalia's rather than becoming a read-only symlink
([noctalia#3101][]).

[noctalia#3101]: https://github.com/noctalia-dev/noctalia/issues/3101

## Deploying to the tv box

`deploy-tv` builds the tv closure on the laptop, `nix copy`s it to the box over
the LAN, asks before switching (only that step interrupts playback), then
activates over `ssh -t` so the box's sudo can prompt for its password on a tty.

There is no passwordless sudo rule for that path, and there cannot be a
meaningfully scoped one: activating a closure runs its code as root, so any
rule that permits it permits arbitrary root execution for anyone holding the
SSH key. The password is typed at the prompt and is not stored in this
repository.

## Notes

- The four "unknown flake output" warnings from `nix flake check`
  (`constants`, `hmDefaults`, `hostModules`, `homeManagerModules`) are
  expected. They are declared so the values merge and compose by name, not
  published. Prefixing them with `_` does *not* silence the warning —
  flake-parts ignores `_`-prefixed declarations under `flake`, so the option
  then resolves to nothing.
- `statix`'s W20 (`repeated_keys`) is filtered out of `nix run .#lint`. statix's own
  `disabled` config only suppresses it for two-occurrence spans and silently
  lets it through from three upwards, so the filter is applied in the script.
- `boot.kernelPackages` is `linuxPackages_latest` on both hosts, so a new
  mainline kernel arrives on every update. The tv's display-mode guard
  (`tv-display.nix`) exists because of that: the EDID marks 1280x720@50 as
  *preferred*, so a kernel that shifts the advertised mode list can silently
  drop the panel to 720p50.
