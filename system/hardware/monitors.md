# Hardware notes (adjust per machine)

- Tablet: XP-Pen Deco Pro MW Gen2 — area 229x143mm mapped to 2560x1440@1280,720 display offset, clipping on, uinput module required.
- GPU: AMD — needs Mesa Vulkan drivers (libvulkan_radeon), vulkaninfo to verify.
- Headset: Logitech PRO X Wireless via headsetcontrol + udev hidraw uaccess rules.
- Monitors: see configs/desktop/umbriel/monitors.toml — display names/positions are machine-specific, re-detect with `umbriel outputs` on new hardware.
- Locale: de-DE keyboard, timezone Europe/Berlin.
