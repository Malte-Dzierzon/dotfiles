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

        # Qt looks for platforms/libqxcb.so under each QT_PLUGIN_PATH entry;
        # the vendor tree keeps it at $out/lib/pentablet/platforms.
        libPath=${lib.makeLibraryPath [libusb1 libX11 libXtst libXrandr libXext libXi libXrender libxcb libSM libICE libxkbcommon glib zlib stdenv.cc.cc.lib dbus libGL fontconfig freetype]}
        makeWrapper $out/lib/pentablet/PenTablet $out/bin/xppentablet \
          --prefix LD_LIBRARY_PATH : "$out/lib/pentablet/lib:$libPath" \
          --set QT_PLUGIN_PATH "$out/lib/pentablet" \
          --set QT_QPA_PLATFORM xcb \
          --set QT_XKB_CONFIG_ROOT "${xkeyboard_config}/share/X11/xkb"
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
