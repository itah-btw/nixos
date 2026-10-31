---
name: nixos
description: Work on this machine's NixOS flake configuration (Umbriel + Noctalia). Use when editing NixOS config, rebuilding, managing packages/services, debugging the desktop, or changing keybinds.
---

# NixOS skill (this machine)

Manage this machine's [NixOS](https://nixos.org/) flake configuration using natural language.

## ⛔ NEVER MODIFY CORE FILES

**DO NOT edit, write, or delete any files in `/nix/store/` or the generated system configuration.**

These are immutable, build outputs. User configuration belongs in `~/Nixos/` instead.

If you need to change behavior controlled by a store path, find or create the corresponding override in `~/Nixos/modules/`.

## Discovery

This flake is dendritic: `flake.nix` → flake-parts + import-tree over `modules/`. Every `.nix` under `modules/` is a flake-parts module.

Features self-register instead of being listed centrally:

- NixOS: `flake.modules.nixos.<name>`
- Home Manager: `flake.modules.homeManager.<name>`

`modules/hosts/nixos/default.nix` composes every `flake.modules.nixos.*` module, and `modules/infrastructure/home-manager.nix` imports every `flake.modules.homeManager.*` module. Adding a feature file is enough to enable it.

### Find Modules / Packages / Services

```bash
# List feature modules
ls ~/Nixos/modules/features/

# Search for a package or option
grep -R "environment.systemPackages" ~/Nixos/modules/
grep -R "home.packages" ~/Nixos/modules/

# Find an alias or shell function
grep -R "shellAliases" ~/Nixos/modules/features/shell.nix

# Inspect flake outputs
nix flake show ~/Nixos

# Read nh / nixos-rebuild help
nh --help
nh os switch --help
nh os rollback --help
nixos-rebuild --help
```

### Command Categories

| Prefix / Tool | Purpose | Example |
|---------------|---------|---------|
| `nixos-rebuild` | Build / switch / test / boot | `nixos-rebuild dry-build --flake ~/Nixos#nixos` |
| `nh os` | Apply / boot / test (nicer UX) | `nh os switch ~/Nixos` |
| `nix flake` | Flake inputs & metadata | `nix flake update` |
| `nix eval` | Inspect a config value | `nix eval --raw ~/Nixos#nixosConfigurations.nixos.config.<path>` |
| `umbriel` | Compositor config tools | `umbriel config validate` |
| `nix-collect-garbage` | GC store paths | `sudo nix-collect-garbage -d` |

## Repository Layout

```
~/Nixos/
├── flake.nix              # flake-parts entry
├── flake.lock             # pinned inputs
├── README.md              # layout, commands, auto-update notes
├── .gitignore
├── modules/
│   ├── features/          # self-registering features (*.nix)
│   ├── hosts/nixos/       # default.nix + hardware.nix
│   ├── infrastructure/    # flake plumbing, Home Manager base, checks
│   ├── btop/              # raw btop.conf
│   ├── fastfetch/         # raw config.jsonc
│   ├── gtk/               # raw GTK CSS
│   ├── kitty/             # raw kitty.conf
│   └── umbriel/           # raw config.toml
└── scripts/               # helper scripts
```

- `modules/hosts/nixos/default.nix` — composes every `flake.modules.nixos.*` automatically. Adding a feature file is enough; there is no central feature list.
- `modules/hosts/nixos/hardware.nix` — disks, boot, kernel modules, `hostPlatform`, and `system.stateVersion`.
- `modules/infrastructure/home-manager.nix` — Home Manager base; auto-imports every `flake.modules.homeManager.*`.
- `modules/infrastructure/checks.nix` — `statix`, `deadnix`, `nixfmt` checks, formatter, and dev shell.
- `modules/infrastructure/nixos.nix` — exposes each NixOS toplevel as a flake check.
- `modules/features/auto-update.nix` — weekly `system.autoUpgrade`.
- `modules/features/mime.nix` — default MIME applications.
- `modules/<app>/` — raw config assets, not modules. `import-tree` only imports `.nix` files, so these are just data.
- `flake.lock` pins inputs; `README.md` documents the layout and commands.

## Identity

- Hostname: `nixos`. User: `itah` (wheel, networkmanager). Timezone: `Asia/Jakarta`. Locale `en_US.UTF-8`, X11 keymap `us`.
- State version: `26.11` in `modules/hosts/nixos/hardware.nix`. Do not change it.
- Unfree allowed. Experimental features `nix-command` and `flakes` enabled.

## Desktop Stack

- Compositor: **Umbriel** (`programs.umbriel.enable`), Wayland (wlroots + SceneFX), session `umbriel.desktop`.
- Shell: **Noctalia** (`programs.noctalia`), autostarted via systemd user service on `graphical-session.target`, with `recommendedServices` (NM, bluetooth, UPower, power profiles).
- Greeter: `services.displayManager.noctalia-greeter` on greetd.
- Kernel: `pkgs.linuxPackages_latest`.
- Audio: PipeWire (alsa + pulse). Speechd disabled (no TTS/espeak/mbrola).
- Portal: only `xdg-desktop-portal-umbriel` (GTK fallback dropped). Umbriel provides ScreenCast + Screenshot.

## Configuration Locations

### Nix (system / home)

```
~/Nixos/modules/
├── features/*.nix
├── hosts/nixos/{default,hardware}.nix
└── infrastructure/*.nix
```

### Umbriel (Window Manager)

`~/Nixos/modules/umbriel/config.toml` (source) → `~/.config/umbriel/config.toml` (writable copy made on every Home Manager activation). Edit the source, then `nrs`; direct runtime edits are overwritten.

```
~/.config/umbriel/
├── config.toml           # main config (sources others)
├── noctalia.toml         # theme written at runtime by Noctalia
└── ...                   # bindings, monitors, etc. live in config.toml
```

### Noctalia (Shell)

Managed via Nix (`programs.noctalia`); runtime state in `~/.config/noctalia/`.

### Other Configs

| App | Source / module | Installed as |
|-----|-----------------|--------------|
| btop | `modules/btop/btop.conf` | writable `~/.config/btop/btop.conf` copy |
| fastfetch | `modules/fastfetch/config.jsonc` | writable `~/.config/fastfetch/config.jsonc`; theme colors merged |
| gtk | `modules/gtk/` | read-only `xdg.configFile` symlinks |
| kitty | `modules/kitty/kitty.conf` | writable `~/.config/kitty/kitty.conf` copy |
| nvim | `modules/features/nvim.nix` | AstroNvim template cloned once to `~/.config/nvim` |
| umbriel | `modules/umbriel/config.toml` | writable `~/.config/umbriel/config.toml` copy |
| yazi | `modules/features/yazi.nix` + `yazi-compress.patch` | Nix module |

## Safe Editing Pattern

When modifying any NixOS config:

### 1. Read Current Config

```bash
cat ~/Nixos/modules/features/<name>.nix
```

### 2. Check the Tree

Commit (or stash) the current tree if needed:

```bash
cd ~/Nixos && git status && git stash   # if needed
```

### 3. Make Changes

Use the Edit tool. Preserve existing structure and comments. Add new files with `git add` afterwards.

### 4. Validate

```bash
# Format the tree
nix fmt

# Lint, formatting check, and NixOS evaluation
nix flake check

# Evaluate without building
nixos-rebuild dry-build --flake ~/Nixos#nixos
```

New files must be `git add`ed before rebuilding (flakes only see tracked files).

`nix flake check` also prints `unknown flake output 'modules'`; this is benign and comes from the dendritic `flake.modules` output.

### 5. Apply Changes

Only do this when the user explicitly asks to activate/switch:

```bash
sudo nixos-rebuild switch --flake ~/Nixos#nixos
# or: nrs
```

### 6. Explain What You Did

After completing changes, include a **Learn More** section:

```
> **Learn More**
>
> [Explain what file(s) were modified or commands were run]
> [Explain why these changes achieve the user's goal]
> [Explain key config options that were set and what they control]
```

## Common Tasks

### Packages

- Feature-specific packages: add them to the owning feature module.
- System-wide packages: `environment.systemPackages` in a NixOS feature.
- Per-user packages: `home.packages` in a Home Manager feature.
- General CLI/GUI packages: `modules/features/packages.nix`.
- `neovim` stays system-wide because `EDITOR`/`VISUAL` point to it.

### Services / Features

Create `modules/features/<name>.nix` and register a NixOS feature:

```nix
_: {
  flake.modules.nixos.<name> = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.<package> ];
  };
}
```

For Home Manager:

```nix
_: {
  flake.modules.homeManager.<name> = { pkgs, ... }: {
    home.packages = [ pkgs.<package> ];
  };
}
```

The host and Home Manager base import all registered modules automatically. Do **not** edit `modules/hosts/nixos/default.nix` to add a feature.

Raw config assets go in `modules/<app>/` (or a feature-owned directory) and are referenced with a relative path.

### Keybinds (Umbriel)

Live in `modules/umbriel/config.toml` under `[keybinds]`. Defining the table replaces the built-in set, so every bind must be listed. Notable binds:

- `Mod` → Noctalia launcher; `Mod+S` control center; `Mod+Shift+S` settings.
- `Mod+Return` → kitty. `Mod+Q` close, `Mod+Shift+Q` kill.
- `Print` / `Shift+Print` / `Ctrl+Print` → screenshot region / fullscreen / window (`--save-to-file --copy-to-clipboard`).
- `Mod+Shift+A` annotate; `Mod+Ctrl+A` annotate overlay.
- `XF86Audio*` → volume/mute; `XF86AudioMicMute`/`XF86MicrophoneMute` → mic mute.
- `XF86MonBrightnessUp/Down` → brightness.
- `Mod+Ctrl+Shift+L` → lock session (via Noctalia).
- `Mod+O` overview; `Mod+Slash` cheatsheet.

Noctalia writes its theme to `~/.config/umbriel/noctalia.toml` at runtime, included via `[include.optional]`.

Validate with `umbriel config validate`.

### Updates

Manual update:

```bash
cd ~/Nixos && nix flake update
sudo nixos-rebuild switch --flake ~/Nixos#nixos
```

`modules/features/auto-update.nix` also enables a weekly `system.autoUpgrade` that:

- updates `nixpkgs`, `home-manager`, `flake-parts`, and `import-tree`;
- rebuilds `/home/itah/Nixos` with `nixos-rebuild switch`;
- does not reboot automatically;
- updates `flake.lock` in place but does not commit it;
- chowns `flake.lock` back to `itah:users`.

Check logs with:

```bash
journalctl -u nixos-upgrade
```

Roll back with `nrr` if an unattended update causes problems. Review and commit `flake.lock` after a successful automatic update.

### Garbage Collection

`nix.gc` runs weekly and keeps 20 generations per profile. Manual cleanup:

```bash
sudo nix-collect-garbage -d
# or: nh clean all --optimise
```

## Troubleshooting

- Greeter failure: `Ctrl+Alt+F2` TTY, then `sudo systemctl disable greetd` or boot previous generation.
- Noctalia not starting: `systemctl --user status noctalia` and `journalctl --user -u noctalia -b`. Autostarts on `graphical-session.target`.
- Volume/mute/brightness keys: verify binary on PATH (module adds `noctalia` to system packages) and PipeWire running (`systemctl --user status pipewire`).
- Brightness uses logind `SetBrightness`; if keys do nothing, check `loginctl show-session $XDG_SESSION_ID` is `Active=yes`.
- Screenshots need Umbriel's `wlr-screencopy` support and per-call flags.
- Portal file dialogs: only Umbriel's portal installed; Flatpak apps need `xdg-desktop-portal-gtk` re-added.
- Auto-update failed: `journalctl -u nixos-upgrade`; `flake.lock` may have been updated but not committed. Roll back with `nrr`.
- Nvim config: first activation clones AstroNvim into `~/.config/nvim`. Delete that directory to re-clone; the config is intentionally mutable.
- MIME defaults: edit `modules/features/mime.nix`, run `nrs`, then check with `xdg-mime query default <type>`.
- Untracked new files cause "file not found" during build — `git add` them.

## NixOS Manual

**IMPORTANT:** For general "how do I" questions, fetch the relevant manual page BEFORE answering. NixOS and Umbriel may have specific approaches.

### When to Fetch the Manual

**Always fetch first** when users ask:
- "How do I..." / "What is..." / "Why does..." questions
- Questions about installing/running software
- Questions about concepts, workflows, or best practices

### Manual Index

| Topic | Keywords | URL |
|-------|----------|-----|
| NixOS Manual | nixos, configuration, options | `https://nixos.org/manual/nixos/stable/` |
| Nix Manual | nix, flakes, language | `https://nixos.org/manual/nix/stable/` |
| Home Manager | home-manager, user config | `https://nix-community.github.io/home-manager/` |
| Umbriel | compositor, wayland, keybinds | `https://github.com/noctalia-dev/umbriel` |
| Umbriel docs | configuration, keybinds | `https://docs.noctalia.dev/umbriel/` |

### Fetching Manual Pages

When a user asks a general question:

1. **Identify relevant topic(s)** from the index above.
2. **Fetch the page** using WebFetch with the full URL.
3. **Extract the answer** from the page content.
4. **Summarize** the relevant information for the user.

## Example Requests

- "Add ripgrep to system packages"
- "Add a Home Manager feature for X"
- "Change the clock format in Noctalia"
- "Add a keybinding for Super+E to open file manager"
- "Make window gaps smaller"
- "Update flake inputs and rebuild"
- "Check the config without switching"
- "Why isn't Noctalia starting?"
- "Why did the weekly auto-update fail?"
- "How do I add a new systemd service?"
- "Set up fingerprint reader"
- "Add Flatpak support (re-add gtk portal)"
