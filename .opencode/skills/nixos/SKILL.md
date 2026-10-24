---
name: nixos
description: Work on this machine's NixOS flake configuration (Umbriel + Noctalia). Use when editing NixOS config, rebuilding, managing packages/services, debugging the desktop, or changing keybinds.
---

# NixOS skill (this machine)

## Repository layout

- Config lives at `~/nixos` (flake). Entry point: `flake.nix` → `nixosConfigurations.nixos`.
- `configuration.nix` — system config (no comments, keep it that way).
- `umbriel/config.toml` — Umbriel compositor config, managed by home-manager (`xdg.configFile`), so it is a read-only store symlink. Edit in the repo, then rebuild.
- `flake.lock` pins nixpkgs to a specific revision.
- `hardware-configuration.nix` — generated; rarely edit by hand.

## Identity

- Hostname: `nixos`. User: `itah` (wheel, networkmanager). Timezone: `Asia/Jakarta`. Locale `en_US.UTF-8`, X11 keymap `us`.
- State version: `26.11`. Do not change it.
- Unfree allowed. Experimental features `nix-command` and `flakes` enabled.

## Desktop stack

- Compositor: **Umbriel** (`programs.umbriel.enable`), Wayland (wlroots + SceneFX), session `umbriel.desktop`.
- Shell: **Noctalia** (`programs.noctalia`), autostarted via systemd user service on `graphical-session.target`, with `recommendedServices` (NM, bluetooth, UPower, power profiles).
- Greeter: `services.displayManager.noctalia-greeter` on greetd.
- Kernel: `pkgs.linuxPackages_latest` (currently 7.3).
- Audio: PipeWire (alsa + pulse). Speechd disabled (no TTS/espeak/mbrola).
- Portal: only `xdg-desktop-portal-umbriel` (GTK fallback dropped to save ~920 MiB). Umbriel provides ScreenCast + Screenshot.

## Common commands

```bash
# Evaluate without building
nixos-rebuild dry-build --flake ~/nixos#nixos

# Apply
sudo nixos-rebuild switch --flake ~/nixos#nixos

# Inspect a value
nix eval --raw ~/nixos#nixosConfigurations.nixos.config.<path>

# Update flake inputs (nixpkgs, home-manager)
cd ~/nixos && nix flake update

# Validate Umbriel config
umbriel config validate

# Garbage collect
sudo nix-collect-garbage -d
```

## Conventions and pitfalls

- **Files must be git-tracked.** A flake in a git repo only sees tracked files. After creating a new file, `git add` it before rebuilding, or the build fails with "file not found". Untracked edits to already-tracked files are still picked up.
- **Commit before/after switching** so the tree stays clean and reproducible.
- **Relative imports resolve to the real file location**, not the symlink path. `configuration.nix` is symlinked from `/etc/nixos`; `./hardware-configuration.nix` resolves to `~/nixos/`, so both files must live together there.
- **Home-manager is integrated as a NixOS module.** Do not also run `home-manager switch` for the same user — it conflicts over `/etc/profiles/per-user/itah`.
- **Do not change `system.stateVersion`.**
- **No comments in `configuration.nix`** — keep it clean.
- **Portal config is forced** via `lib.mkForce [ pkgs.xdg-desktop-portal-umbriel ]`; if Flatpak is added later, re-add `pkgs.xdg-desktop-portal-gtk`.

## Keybinds (Umbriel)

Live in `umbriel/config.toml` under `[keybinds]`. Defining the table replaces the built-in set, so every bind must be listed. Notable binds:

- `Mod` → Noctalia launcher; `Mod+S` control center; `Mod+Shift+S` settings.
- `Mod+Return` → kitty. `Mod+Q` close, `Mod+Shift+Q` kill.
- `Print` / `Shift+Print` / `Ctrl+Print` → screenshot region / fullscreen / window (with `--save-to-file --copy-to-clipboard`).
- `Mod+Shift+A` annotate; `Mod+Ctrl+A` annotate overlay.
- `XF86Audio*` → volume/mute; `XF86AudioMicMute`/`XF86MicrophoneMute` → mic mute.
- `XF86MonBrightnessUp/Down` → brightness.
- `Mod+Shift+L` → lock session (via Noctalia).
- `Mod+O` overview; `Mod+Slash` cheatsheet.

Noctalia writes its theme to `~/.config/umbriel/noctalia.toml` at runtime, included via `[include.optional]`.

## Troubleshooting

- Greeter failure: `Ctrl+Alt+F2` TTY, then `sudo systemctl disable greetd` or boot previous generation.
- Noctalia not starting: check `systemctl --user status noctalia` and `journalctl --user -u noctalia -b`. It autostarts on `graphical-session.target`.
- Volume/mute/brightness keys: verify the binary is on PATH (module adds `noctalia` to system packages) and PipeWire is running (`systemctl --user status pipewire`).
- Brightness uses logind `SetBrightness`; if keys do nothing, check `loginctl show-session $XDG_SESSION_ID` is `Active=yes`.
- Screenshots need Umbriel's `wlr-screencopy` support (present) and the per-call flags; default `[shell.screenshot]` policy can also be set in Noctalia settings.
- Portal file dialogs: only Umbriel's portal is installed; Flatpak apps will lack a FileChooser backend unless `xdg-desktop-portal-gtk` is re-added.

## Adding packages

- System-wide: `environment.systemPackages`.
- Per-user: `home-manager.users.itah.home.packages`.
- New service: add to `configuration.nix`, dry-build, commit, switch.
