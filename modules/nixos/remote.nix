{lib, ...}: {
  # Remote access: plain OpenSSH on LAN + Tailscale. Key auth preferred;
  # password auth stays ON until the user confirms a working key login.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };
  # Regular OpenSSH over the tailnet (not Tailscale SSH) — one access model.
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
  };
  networking.firewall = {
    trustedInterfaces = ["tailscale0"];
    allowedUDPPorts = [41641];
  };
  # Login requires manual `sudo tailscale up` once (no tokens in repo).
}
