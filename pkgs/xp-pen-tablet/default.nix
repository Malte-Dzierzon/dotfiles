{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  libusb1,
  libX11,
  libXtst,
  libXrandr,
  libXext,
  libXi,
  libXrender,
  libxcb,
  libSM,
  libICE,
  libxkbcommon,
  glib,
  zlib,
  dbus,
  libGL,
  fontconfig,
  freetype,
  xkeyboard_config,
}:
stdenv.mkDerivation rec {
  pname = "xp-pen-tablet";
  version = "4.0.15-260422";

  src = fetchurl {
    url = "https://download01.xp-pen.com/file/2026/04/XPPenLinux4.0.15-260422.tar.gz";
    sha256 = "19czwmbgqqvlna7k554dvbnl2kk87y724d736aakk7zajvx759r5";
  };

  nativeBuildInputs = [makeWrapper];

  unpackPhase = "tar xzf $src";

  installPhase = ''
        runHook preInstall
        app=XPPenLinux${version}/App
        mkdir -p $out/lib/pentablet $out/share
        cp -r $app/usr/lib/pentablet/* $out/lib/pentablet/
        chmod +x $out/lib/pentablet/PenTablet
        cp -r $app/usr/share/* $out/share/

    # The driver writes its config next to the binary (conf/xppen/*.xml) —
    # read-only in the store, which triggers a bogus "need root" dialog.
    # Launcher seeds a writable copy to ~/.local/share and runs it there.
    libPath=${lib.makeLibraryPath [libusb1 libX11 libXtst libXrandr libXext libXi libXrender libxcb libSM libICE libxkbcommon glib zlib stdenv.cc.cc.lib dbus libGL fontconfig freetype]}
    mkdir -p $out/bin
    cat > $out/bin/xppentablet <<WRAPPER
    #!${stdenv.shell} -e
    DEST="\$HOME/.local/share/xppentablet"
    MARK="\$DEST/.version"
    if [[ ! -f "\$MARK" ]] || [[ "\$(cat \$MARK)" != "${version}" ]]; then
      rm -rf "\$DEST"
      mkdir -p "\$DEST"
      cp -r $out/lib/pentablet/* "\$DEST/"
      chmod -R u+w "\$DEST"
      chmod +x "\$DEST/PenTablet"
      echo "${version}" > "\$MARK"
    fi
    export LD_LIBRARY_PATH="\$DEST/lib:${libPath}:\$LD_LIBRARY_PATH"
    export QT_PLUGIN_PATH="\$DEST"
    export QT_QPA_PLATFORM=xcb
    export QT_XKB_CONFIG_ROOT="${xkeyboard_config}/share/X11/xkb"
    # Qt single-instance socket per user (avoids /tmp collisions).
    export TMPDIR="\''${XDG_RUNTIME_DIR:-\/tmp}"
    exec "\$DEST/PenTablet" "\$@"
    WRAPPER
    chmod +x $out/bin/xppentablet
        # udev rules: vendor MODE=0666 becomes uaccess (logged-in user only).
        mkdir -p $out/lib/udev/rules.d
        cat > $out/lib/udev/rules.d/10-xp-pen.rules <<EOF
    KERNEL=="uinput", SUBSYSTEM=="misc", TAG+="uaccess", OPTIONS+="static_node=uinput"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="28bd", TAG+="uaccess"
    EOF
        substituteInPlace $out/share/applications/xppentablet.desktop \
          --replace "/usr/lib/pentablet/PenTablet.sh" "$out/bin/xppentablet"

        runHook postInstall
  '';

  # Vendor ships prebuilt binaries; no stripping/patching of RPATH needed.
  dontStrip = true;
  dontPatchELF = true;

  meta = with lib; {
    description = "XP-Pen official Linux driver (PenTablet UI)";
    homepage = "https://www.xp-pen.com/download/deco-pro-gen-2-series.html";
    sourceProvenance = with sourceTypes; [binaryNativeCode];
    license = licenses.unfree;
    platforms = ["x86_64-linux"];
    mainProgram = "xppentablet";
  };
}
