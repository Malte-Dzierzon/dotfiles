#!/usr/bin/env python3
"""Noctalia post-hook: expand #rrggbb placeholders in rendered colorfilters template
into Wireshark 16-bit decimal [r,g,b] triplets. Usage: wireshark-apply.py <rendered-in>"""
import re, sys, os

def hex_to_16(h: str) -> str:
    h = h.lstrip('#')
    r, g, b = int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)
    return f"[{r * 257},{g * 257},{b * 257}]"

def main() -> None:
    src = sys.argv[1]
    profile = os.path.expanduser("~/.config/wireshark/profiles/Noctalia")
    os.makedirs(profile, exist_ok=True)
    with open(src) as f:
        text = f.read()
    text = re.sub(r"#([0-9a-fA-F]{6})", lambda m: hex_to_16(m.group(0)), text)
    with open(os.path.join(profile, "colorfilters"), "w") as f:
        f.write(text)
    print(f"wrote {profile}/colorfilters")

if __name__ == "__main__":
    main()
