# nixos

Two NixOS hosts and one Home Manager, as a [dendritic][dendritic] flake.

| Host | Session | Role |
| --- | --- | --- |
| `hp` | Umbriel + Noctalia Shell, Noctalia Greeter | Laptop: desktop, mail, development |
| `tv` | Plasma Big Screen, SDDM autologin | Appliance: Stremio, local media on `/mnt/media` |

[dendritic]: https://github.com/nix-community/flake-parts/wiki/Dendritic-Pattern

## Layout

```
flake.nix                 inputs + the entry point; no logic
hardware-configuration*.nix   generated, never hand-edited
modules/
  options.nix             flake-private plumbing (wiring table, constants) + mkHost
  formatter.nix           `nix fmt` (nixfmt + stylua) and `nix run .#lint` (deadnix + statix)
  checks.nix              policy guards, run by `nix flake check`
  <feature>.nix           one feature, named after what it configures
  hosts/hp.nix            composition point for hp
  hosts/tv.nix            composition point for tv
nvf/
  *.lua                   hand-written Lua, read as text by nvf.nix
```

## Conventions

**The filename is the module name.** `modules/nix.nix` defines
`flake.nixosModules.nix`. There are no layer folders (`core/`, `home/`, `tv/`)
because the layer is expressed by the namespace, not the directory — a feature
like `mariadb.nix` legitimately owns both `nixosModules.mariadb` and
`homeManagerModules.mariadb`, and one file says so honestly. The `tv-` prefix
on the tv host's modules is load-bearing for the same reason: the directory no
longer namespaces, so the name has to. `checks.tv-prefix` enforces it in both
directions, against a *derived* shared list rather than a hand-maintained one —
an unprefixed name may only reach tv if another host also has it, and a `tv-`
name may reach no other host.

**A module file declares one feature and nothing else.** Cross-references go in
comments ("xkb lives in locale.nix"), never in imports. The only path imports
in the flake are the two generated `hardware-configuration*.nix` files.

A single application with real config gets its own file for the same reason —
`yazi.nix` and `tridactyl.nix` are both one app each. Judge on content, not on
whether an app is an app: yazi's 155 lines of mime rules and keybinds was 60% of
`apps.nix`, crowding out four 6–15 line blocks, so it moved out and `apps.nix`
is now the small stuff it always should have been. Desktop integration can
still span two modules — `yazi.nix` overrides yazi's `.desktop` to run under
kitty, and `apps.nix` owns kitty — which is why those cross-links are comments
and not imports. The counter-case is `nvf.nix`: its 256-line keymap list is the
same shape, but keymaps are meaningless apart from the options they bind, so
splitting them would leave two files that are neither complete nor checkable on
their own. The test is whether a block has a reason to change independently.

**Host files are declarations; the scaffolding is `mkHost`.** `options.nix` holds
the `nixosSystem` call, and each `modules/hosts/*.nix` passes a name, a wiring
table, its hardware file and a few inline settings. `mkHost` is threaded in
through `_module.args` rather than `config.flake.mkHost`, for two reasons worth
knowing before you move it: the host files are in `imports`, so reading `config`
at their top level asks the module system for the config it is still
assembling, and `options.nix` cannot define a plain `flake.*` attribute at all,
because declaring `options.*` makes it a module whose top level may only be
`config`/`options`.

**Data a module reads is not a module.** The hand-written Lua for nvf lives in
`nvf/*.lua` and is pulled in with `builtins.readFile`, so stylua can format it
and `checks.treefmt` can parse it — neither works on a Nix string literal. The
one value the Lua needs from `flake.constants` arrives as a `@@TOKEN@@` inside a
Lua string and is substituted in `nvf.nix`; `nvf-lua-wired` asserts the file
list and the `readLua` calls still agree.

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
| `nix fmt` | nixfmt + stylua. Safe to run implicitly; `push` does it for you. |
| `nix run .#lint` | deadnix + statix, **check-only** — reports, never rewrites. |
| `nix flake check` | treefmt check (which also parses the nvf Lua) plus the policy guards. |
| `rb` / `dry` / `nsu` / `ntest` | rebuild, dry build, switch+update, test. |
| `deploy-tv` | build the tv closure here, copy it over the LAN, then activate. |

`nix fmt` deliberately does *not* run deadnix or statix. They are fixers, and
leaving them in the formatter meant `push` swept unrelated auto-fixes from other
modules into whatever you happened to be committing. stylua is in the formatter
rather than the linters because it only reflows what is already correct.

## Policy guards

`checks.nix` builds a single derivation that runs every rule as a jq predicate
over one JSON description of the flake, so one `nix flake check` reports every
failure at once. Rules are written as `all(.[]; ...)` over the per-host facts
rather than repeated per host: a rule for a feature only one host has is
vacuous on the other, and a vacuous check still costs a build while reading as
if it were protecting something.

Current rules: `modules-wired`, `dual-namespace-wired`, `tv-prefix`,
`constants-intact`, `host-identity`, `single-dm`, `greeter-implies-greetd`,
`no-tts`, `no-x-server`, `firewall`, `auto-gc`, `binary-cache`,
`mariadb-loopback`, `noctalia-theming-runtime`, `noctalia-single-launcher`,
`starship-unmanaged`, `umbriel-repeat-trap`, `nvf-lua-wired`,
`nvf-palette-nix-only`.

The first three are about the wiring itself, and all three are things that used
to be prose. `tv-prefix` is the clearest case: the `tv-` prefix was documented as
load-bearing, and the rule found a real violation on its first run — `hdd.nix`
was tv-only and unprefixed, and is now `tv-hdd.nix`. `dual-namespace-wired`
deliberately constrains only a module a host actually wires, so "present means
both halves" rather than "every dual module appears in both lists" — the
stronger form would reject a host that legitimately needs just the nixos half.

`checks.nix` also checks itself: a fact that no rule reads is an eval-time
error, because an unread fact is not free — it is still built on every
`nix flake check`.

The last four encode decisions that are easy to break by accident and hard to
notice when broken: Noctalia's theme, wallpaper and palettes must stay
runtime-managed (setting them in Home Manager stops wallpaper-derived palettes
and rotation), Noctalia must be started by Umbriel and not also by systemd,
`starship.toml` must stay Noctalia's rather than becoming a read-only symlink
([noctalia#3101][]), the four Umbriel chords that must be written in table form
must not become plain strings, and the editor palette must stay written down in
exactly one place.

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
