# Nuvio: the Stremio-addon media client. Upstream ships no nixpkgs package --
# only AppImage/deb/rpm/flatpak -- so the AppImage is wrapped with appimageTools
# and pinned by sha256. Alpha upstream: the tag itself carries -alpha, and
# releases land roughly weekly, so this pin goes stale fast.
{
  flake.nixosModules.nuvio =
    { pkgs, ... }:
    let
      version = "0.1.26-alpha";

      src = pkgs.fetchurl {
        url = "github.com/NuvioMedia/NuvioDesktop/releases/download/${version}/Nuvio-Linux-x86_64-${version}.AppImage";
        hash = "sha256-NnXsPEF99eNZf8pGPwbCcRkXbcZPdbmZLdLGnXVjNHk=";
        # appimage-exec.sh runs the image itself, so the bit has to be set.
        postFetch = "chmod +x $src";
      };

      # Extracted once and handed to the wrapper, so the desktop entry and the
      # icon come from the same AppImage the binary runs.
      extracted = pkgs.appimageTools.extract {
        pname = "nuvio";
        inherit version src;
      };

      nuvio = pkgs.appimageTools.wrapAppImage {
        pname = "nuvio";
        inherit version src;
        contents = extracted;
        # MPVKit needs libmpv; the image bundles one, this is the fallback.
        extraPkgs = pkgs: [ pkgs.mpv ];
        extraInstallCommands = ''
          install -Dm444 ${extracted}/Nuvio.desktop $out/share/applications/nuvio.desktop
          install -Dm444 ${extracted}/Nuvio.png $out/share/icons/hicolor/512x512/apps/nuvio.png
          # The shipped Exec is AppRun, which only exists inside the image; the
          # wrapper's own binary is what a desktop entry may launch.
          substituteInPlace $out/share/applications/nuvio.desktop \
            --replace-fail 'Exec=AppRun %u' 'Exec=nuvio %u' \
            --replace-fail 'Icon=Nuvio' 'Icon=nuvio'
        '';
        meta = {
          description = "Nuvio media player, a Stremio-addon client";
          homepage = "https://nuvio.tv";
          license = pkgs.lib.licenses.gpl3Only;
          mainProgram = "nuvio";
          platforms = [ "x86_64-linux" ];
          sourceProvenance = pkgs.lib.sourceTypes.binaryNativeCode;
        };
      };
    in
    {
      # systemPackages, not Home Manager, so the .desktop reaches the Plasma
      # Bigscreen app grid as well as hp's launcher.
      environment.systemPackages = [ nuvio ];
    };
}
