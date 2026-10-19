
mkdir -p /tmp/extra-files/etc/nixos
cp ./age.agekey /tmp/extra-files/etc/nixos/age.agekey
chmod 600 /tmp/extra-files/etc/nixos/age.agekey

nix run github:nix-community/nixos-anywhere -- --flake .#$2 --extra-files /tmp/extra-files --generate-hardware-config nixos-generate-config $3/hardware-configuration.nix $1

rm -rf /tmp/extra-files
