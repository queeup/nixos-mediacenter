# https://lazamar.co.uk/nix-versions/
# let
#   pkgs = import (builtins.fetchTarball {
#     url = "https://github.com/NixOS/nixpkgs/archive/5a8650469a9f8a1958ff9373bd27fb8e54c4365d.tar.gz";
#   }) {};
#   myPkg-linux-firmware = pkgs.linux-firmware;
# in

# https://discourse.nixos.org/t/installing-only-a-single-package-from-unstable/5598/4
#let
#  unstable = import
#    (builtins.fetchTarball https://github.com/NixOS/nixpkgs-channels/archive/nixos-unstable.tar.gz)
#    # reuse the current configuration
#    { config = config.nixpkgs.config; };
#in

# https://lazamar.co.uk/nix-versions/
# let
#   pkgs = import (builtins.fetchTarball {
#     url = "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";
#   }) {};
#   unstable-tailscale = pkgs.tailscale;
# in

{ pkgs, config, ... }:

let
  unstable = import
    (builtins.fetchTarball {
      url = https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz;
      }
    )
    # reuse the current configuration
    { config = config.nixpkgs.config; };
in

{
  environment = {
    systemPackages = with pkgs; [
      unstable.tailscale
      unstable.atuin
      unstable.bash-preexec
      # unstable.blesh
    ];
    interactiveShellInit = ''
      source ${unstable.bash-preexec}/share/bash/bash-preexec.sh
      # source ${unstable.blesh}/share/blesh/ble.sh
      eval "$(${unstable.atuin}/bin/atuin init bash)"
    '';
  };
  services.tailscale.package = unstable.tailscale;
  # services.atuin.package = unstable.atuin;
}
