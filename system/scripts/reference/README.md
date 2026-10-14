# Historical reference scripts (NOT portable, do not execute)

Snapshots from the old NixOS setup, kept as logic documentation only.
All contain hardcoded `/nix/store` or `/etc/profiles` paths:

| script | purpose | openSUSE replacement |
|---|---|---|
| filius | launch Filius .jar via nix java | `java -jar <path>/filius.jar` with distro temurin |
| pakmc | LD_LIBRARY_PATH shim for libcrypt | usually unneeded; distro libcrypt |
| slipper | rockyou wordlist lookup in /nix/store | point at distro wordlist |
| zapfast (+-noctalia-sync) | GPU-lib shim launcher | run binary directly, distro libs |
| omp-mic | pulseaudio LD_LIBRARY_PATH shim | unneeded with distro pipewire |
| qalculate-qt-themed | qt plugin path shim | distro qt6ct handles it |
| prism-noctalia-sync | copy theme into Prism data dir | manual: copy `themes/Noctalia` to PrismLauncher themes |
