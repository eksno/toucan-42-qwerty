{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    zmk-nix = {
      url = "github:lilyinstarlight/zmk-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, zmk-nix }: let
    forAllSystems = nixpkgs.lib.genAttrs (nixpkgs.lib.attrNames zmk-nix.packages);
  in {
    packages = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      buildKeyboard = zmk-nix.legacyPackages.${system}.buildKeyboard;

      commonArgs = {
        src = nixpkgs.lib.sourceFilesBySuffices self [
          ".board" ".cmake" ".conf" ".defconfig" ".dts" ".dtsi"
          ".json" ".keymap" ".overlay" ".shield" ".yml" "_defconfig"
        ];
        board = "seeeduino_xiao_ble";
        zephyrDepsHash = "sha256-63E95iZ/uJRgs6YOmEOUrtd9UM22oquof3a+O4wTIgs=";
      };
    in rec {
      default = firmware;

      firmware-left = buildKeyboard (commonArgs // {
        name = "zmk-left";
        shield = "toucan_left rgbled_adapter nice_view_gem";
        enableZmkStudio = true;
      });

      firmware-right = buildKeyboard (commonArgs // {
        name = "zmk-right";
        shield = "toucan_right rgbled_adapter";
      });

      firmware = pkgs.runCommand "firmware" {
        parts = [ "left" "right" ];
        meta = {
          description = "ZMK firmware for Beekeeb Toucan";
          license = nixpkgs.lib.licenses.mit;
          platforms = nixpkgs.lib.platforms.all;
        };
      } ''
        mkdir $out
        cp ${firmware-left}/zmk.uf2  $out/zmk_left.uf2
        cp ${firmware-right}/zmk.uf2 $out/zmk_right.uf2
      '';

      flash = zmk-nix.packages.${system}.flash.override { inherit firmware; };
      update = zmk-nix.packages.${system}.update;

      keymap-pdf = pkgs.writeShellApplication {
        name = "keymap-pdf";
        runtimeInputs = [ pkgs.keymap-drawer pkgs.librsvg pkgs.gnused pkgs.coreutils ];
        text = ''
          keymap_file="''${1:-config/toucan.keymap}"
          out_file="''${2:-keymap.pdf}"

          tmpdir="$(mktemp -d)"
          trap 'rm -rf "$tmpdir"' EXIT

          keymap parse -z "$keymap_file" > "$tmpdir/k.yaml"
          sed -i 's|^layout: .*|layout: {ortho_layout: {split: true, rows: 3, columns: 6, thumbs: 3}}|' "$tmpdir/k.yaml"
          keymap draw "$tmpdir/k.yaml" > "$tmpdir/k.svg"

          rsvg-convert -f pdf -o "$out_file" "$tmpdir/k.svg"
          echo "Wrote $out_file"
        '';
      };
    });

    devShells = forAllSystems (system: {
      default = zmk-nix.devShells.${system}.default;
    });
  };
}
