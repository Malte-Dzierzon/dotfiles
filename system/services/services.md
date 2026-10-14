# Services (openSUSE equivalents of NixOS modules)

| NixOS module | openSUSE |
|---|---|
| PipeWire+rtkit | pipewire pipewire-pulseaudio wireplumber rtkit, systemctl --user enable pipewire |
| OpenTabletDriver daemon | otd-daemon.service --user, enable after install |
| greetd + noctalia-greeter | greetd with noctalia-greeter (or SDDM fallback) |
| NetworkManager/bluetooth | NetworkManager + bluez, systemctl enable |
| tailscale | tailscale package, `tailscale up` (manual approval) |
| docker | docker, enable only if used |
| headsetcontrol | run manually, no daemon |
