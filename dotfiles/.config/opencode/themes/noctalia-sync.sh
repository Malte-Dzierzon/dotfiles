#!/usr/bin/env bash
# noctalia-sync.sh – regeneriert das opencode-Theme "noctalia" (V2-Format:
# base + dark/light mit Hue-Skalen) aus den live von Noctalia generierten Farben.
#
# Quellen (Prioritaet):
#   1. ~/.config/zed/themes/noctalia.json (vollstaendig: dark + light)
#   2. ~/.config/kitty/themes/noctalia.conf (nur dark live, Rest Defaults)
#
# Live-Theming: in Noctalia unter Settings -> Hooks -> "colorGeneration"
# dieses Skript eintragen. Es laeuft dann bei jedem Wallpaper-/Scheme-Wechsel.
set -euo pipefail

ZED="${HOME}/.config/zed/themes/noctalia.json"
KITTY="${HOME}/.config/kitty/themes/noctalia.conf"
OUT="${HOME}/.config/opencode/themes/noctalia.json"

# --- Ankerfarben einsammeln -------------------------------------------------
if [[ -f "$ZED" ]]; then
  SRC="zed"
  ANCHORS=$(jq -r '
    (.themes[] | select(.name == "Noctalia Dark") | .style) as $d
    | (.themes[] | select(.name == "Noctalia Light") | .style) as $l
    | {
        dark: {
          bg: $d.background, element: $d."element.background",
          elevated: $d."elevated_surface.background",
          text: $d.text, muted: $d."text.muted", border: $d.border,
          primary: $d.accents[0], secondary: $d.accents[1],
          tertiary: $d.accents[2], error: $d.error
        },
        light: {
          bg: $l.background, element: $l."element.background",
          text: $l.text, muted: $l."text.muted", border: $l.border,
          subtle: $l."border.variant",
          primary: $l.accents[0], secondary: $l.accents[1],
          tertiary: $l.accents[2], error: $l.error
        }
      }' "$ZED")
  # dark subtle (mittleres Grau) aus der Kitty-Palette, gehoert zum selben Noctalia-Stand
  SUBTLE_D=$(grep -m1 -oP '^color8\s+\K#[0-9a-fA-F]{6}' "$KITTY" 2>/dev/null || echo "#8d9195")
  ANCHORS=$(jq --arg s "$SUBTLE_D" '.dark.subtle = $s' <<<"$ANCHORS")
elif [[ -f "$KITTY" ]]; then
  SRC="kitty-fallback"
  kv() { grep -m1 -oP "^${1}\s+\K#[0-9a-fA-F]{6}" "$KITTY"; }
  ANCHORS=$(jq -n \
    --arg bg "$(kv background)" --arg fg "$(kv foreground)" \
    --arg black "$(kv 'color0')" --arg red "$(kv 'color1')" \
    --arg green "$(kv 'color2')" --arg blue "$(kv 'color4')" \
    --arg cyan "$(kv 'color6')" --arg brightblack "$(kv 'color8')" \
    '{
      dark: {
        bg: $bg, element: "#1f2020", elevated: "#292a2b",
        text: $fg, muted: "#c3c7cb", subtle: $brightblack, border: $black,
        primary: $green, secondary: $cyan, tertiary: $blue, error: $red
      },
      light: {
        bg: "#fbf9f9", element: "#efedee",
        text: "#1b1c1c", muted: "#42474b", border: "#c3c7cb", subtle: "#73787b",
        primary: "#4a5f6a", secondary: "#585f64", tertiary: "#66576b", error: "#ba1a1a"
      }
    }')
else
  echo "noctalia-sync: keine Noctalia-Farbquelle gefunden (weder $ZED noch $KITTY)" >&2
  exit 1
fi

# --- V2-Theme aufbauen (Hue-Skalen: Step 200 = exakte Live-Farbe) ------------
jq '
  def hd: {"0":0,"1":1,"2":2,"3":3,"4":4,"5":5,"6":6,"7":7,"8":8,"9":9,"a":10,"b":11,"c":12,"d":13,"e":14,"f":15};
  def h2d: ascii_downcase | hd[.[0:1]] * 16 + hd[.[1:2]];
  def rgb: {r: .[1:3] | h2d, g: .[3:5] | h2d, b: .[5:7] | h2d};
  def hx: ["0","1","2","3","4","5","6","7","8","9","a","b","c","d","e","f"];
  def hx2: hx[(./16 | floor)] + hx[(.%16)];
  def ch($v): if $v < 0 then 0 elif $v > 255 then 255 else ($v | round) end;
  def mix($A; $B; $t):
    ($A | rgb) as $a | ($B | rgb) as $b
    | "#" + ([ch($a.r + ($b.r - $a.r) * $t),
               ch($a.g + ($b.g - $a.g) * $t),
               ch($a.b + ($b.b - $a.b) * $t)] | map(hx2) | join(""));
  # dark: 100 hell -> 900 dunkel; light: 100 dunkel -> 900 hell
  def dscale($c; $fg; $bg): {
    "100": mix($c; $fg; 0.55), "200": $c,
    "300": mix($c; $bg; 0.20), "400": mix($c; $bg; 0.38),
    "500": mix($c; $bg; 0.55), "600": mix($c; $bg; 0.70),
    "700": mix($c; $bg; 0.82), "800": mix($c; $bg; 0.90),
    "900": mix($c; $bg; 0.96)};
  def lscale($c; $fg; $bg): {
    "100": mix($c; $fg; 0.55), "200": $c,
    "300": mix($c; $bg; 0.25), "400": mix($c; $bg; 0.40),
    "500": mix($c; $bg; 0.55), "600": mix($c; $bg; 0.68),
    "700": mix($c; $bg; 0.78), "800": mix($c; $bg; 0.87),
    "900": mix($c; $bg; 0.93)};
  . as $A | $A.dark as $d | $A.light as $l
  | {
      "$schema": "https://opencode.ai/theme.json",
      "base": {
        "categorical": ["accent", "cyan", "purple", "blue"],
        "text": {
          "base": "$hue.neutral.100", "muted": "$hue.neutral.300",
          "action": {
            "primary":   {"base": "$hue.interactive.200", "$hovered": "$hue.interactive.100",
                          "$focused": "$hue.interactive.100", "$pressed": "$hue.interactive.300",
                          "$selected": "$hue.interactive.200", "$disabled": "$text.muted"},
            "secondary": {"base": "$text.muted", "$hovered": "$text.base"},
            "destructive": {"base": "$hue.red.200", "$disabled": "$text.muted"}
          },
          "formfield": {"base": "$hue.neutral.100", "$hovered": "$hue.interactive.100",
                        "$focused": "$hue.interactive.100", "$pressed": "$hue.interactive.200",
                        "$selected": "$hue.interactive.100", "$disabled": "$text.muted"},
          "feedback": {
            "error":   {"base": "$hue.red.200",    "muted": "$hue.red.400"},
            "warning": {"base": "$hue.yellow.200", "muted": "$hue.yellow.400"},
            "success": {"base": "$hue.green.200",  "muted": "$hue.green.400"},
            "info":    {"base": "$hue.cyan.300",   "muted": "$hue.cyan.400"}
          }
        },
        "background": {
          "base": "$hue.neutral.800",
          "raised": {"base": "$hue.neutral.700", "high": "$hue.neutral.600", "max": "$hue.neutral.500"},
          "action": {
            "primary":   {"base": "transparent", "$hovered": "$background.raised.high",
                          "$focused": "$hue.interactive.200", "$selected": "transparent"},
            "secondary": {"base": "transparent"},
            "destructive": {"base": "$hue.red.200"}
          },
          "formfield": {"base": "$background.base"},
          "feedback": {
            "error": {"base": "$background.base"}, "warning": {"base": "$background.base"},
            "success": {"base": "$background.base"}, "info": {"base": "$background.base"}
          }
        },
        "border": {"base": "$hue.neutral.600"},
        "scrollbar": {"base": "$hue.neutral.400"},
        "diff": {
          "text": {"added": "$hue.green.200", "removed": "$hue.red.200",
                   "context": "$hue.neutral.300", "hunkHeader": "$hue.cyan.200"},
          "background": {"added": "$hue.green.900", "removed": "$hue.red.900",
                         "context": "$hue.neutral.800"},
          "highlight": {"added": "$hue.green.700", "removed": "$hue.red.700"},
          "lineNumber": {"text": "$hue.neutral.400",
                         "background": {"added": "$hue.green.800", "removed": "$hue.red.800"}}
        },
        "syntax": {
          "comment": "$hue.neutral.400", "keyword": "$hue.blue.200",
          "function": "$hue.cyan.200", "variable": "$hue.neutral.100",
          "string": "$hue.purple.200", "number": "$hue.purple.300",
          "type": "$hue.cyan.300", "operator": "$hue.neutral.300",
          "punctuation": "$hue.neutral.400"
        },
        "markdown": {
          "text": "$hue.neutral.100", "heading": "$hue.cyan.200",
          "link": "$hue.blue.200", "linkText": "$hue.cyan.200",
          "code": "$hue.purple.200", "blockQuote": "$hue.neutral.300",
          "emphasis": "$hue.blue.300", "strong": "$hue.cyan.200",
          "horizontalRule": "$hue.neutral.500", "listItem": "$hue.cyan.200",
          "listEnumeration": "$hue.blue.300", "image": "$hue.purple.200",
          "imageText": "$hue.blue.200", "codeBlock": "$hue.neutral.100"
        },
        "@dialog": {"background": {"base": "$background.raised.base",
                                    "action": {"primary": {"$hovered": "$background.raised.high"}}}}
      },
      "dark": {
        "hue": {
          "gray":  {"100": $d.text, "200": $d.muted, "300": mix($d.muted; $d.subtle; 0.45),
                    "400": $d.subtle, "500": mix($d.subtle; $d.border; 0.5),
                    "600": $d.border, "700": $d.elevated, "800": $d.bg,
                    "900": mix($d.bg; "#000000"; 0.45)},
          "red": dscale($d.error; $d.text; $d.bg),
          "orange": "$hue.red",
          "yellow": "$hue.purple",
          "green": "$hue.cyan",
          "cyan": dscale($d.primary; $d.text; $d.bg),
          "blue": dscale($d.secondary; $d.text; $d.bg),
          "purple": dscale($d.tertiary; $d.text; $d.bg),
          "accent": "$hue.cyan", "interactive": "$hue.cyan", "neutral": "$hue.gray"
        }
      },
      "light": {
        "hue": {
          "gray":  {"100": $l.text, "200": $l.muted, "300": $l.subtle,
                    "400": mix($l.subtle; $l.border; 0.5), "500": $l.border,
                    "600": mix($l.border; $l.element; 0.55), "700": $l.element,
                    "800": $l.bg, "900": mix($l.bg; "#ffffff"; 0.6)},
          "red": lscale($l.error; $l.text; $l.bg),
          "orange": "$hue.red",
          "yellow": "$hue.purple",
          "green": "$hue.cyan",
          "cyan": lscale($l.primary; $l.text; $l.bg),
          "blue": lscale($l.secondary; $l.text; $l.bg),
          "purple": lscale($l.tertiary; $l.text; $l.bg),
          "accent": "$hue.cyan", "interactive": "$hue.cyan", "neutral": "$hue.gray"
        },
        "border": {"base": "$hue.neutral.500"}
      }
    }' <<<"$ANCHORS" > "${OUT}.tmp"

# --- Validierung: alle Color-Links ($-Referenzen) aufloesbar -----------------
REPORT=$(jq '
  # Folgt $-Ketten (z.B. $hue.green.200 -> Alias $hue.cyan -> Hex), mit Zyklus-Schutz
  def resolve($parts; $root):
    {p: $parts, n: $root, i: 0}
    | until(.done;
        if .i > 50 then .done = true | .failed = true
        elif (.p | length) == 0 then .done = true
        elif (.n | type) != "object" then .done = true | .failed = true
        else (.n[.p[0]]) as $v
          | if $v == null then .done = true | .failed = true
            elif (($v | type) == "string" and ($v | startswith("$"))) then
              {p: (($v[1:] | split(".")) + .p[1:]), n: $root, i: (.i + 1)}
            else {p: .p[1:], n: $v, i: (.i + 1)}
            end
        end)
    | if .failed then empty else .n end;
  def resolveRef($ref; $root): resolve(($ref[1:] | split(".")); $root);
  def hexok: type == "string" and (test("^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$") or . == "transparent");
  def check($m):
    (if $m == "dark" then .dark else .light end) as $mode
    | ({hue: $mode.hue} + (.base * ($mode | del(.hue)))) as $scope
    | ([.. | strings | select(startswith("$"))] | unique) as $refs
    | {
        mode: $m,
        refs: ($refs | length),
        broken: [$refs[] | select(resolveRef(.; $scope) == null)],
        nonhex: [$refs[]
                 | select((split(".") | length) > 2)
                 | {ref: ., got: resolveRef(.; $scope)}
                 | select(.got | hexok | not)]
      };
  {dark: check("dark"), light: check("light")}' "${OUT}.tmp")

BROKEN=$(jq -r '[.dark.broken[], .light.broken[], .dark.nonhex[], .light.nonhex[]] | length' <<<"$REPORT")
if [[ "$BROKEN" != "0" ]]; then
  echo "noctalia-sync: kaputte Color-Links:" >&2
  jq . <<<"$REPORT" >&2
  exit 1
fi
# Hue-Vollstaendigkeit: 8 Basis-Hues x 9 Steps + 3 Aliase, je Mode
for m in dark light; do
  STEPS=$(jq -r --arg m "$m" '.[$m].hue | [.gray,.red,.cyan,.blue,.purple] | map(keys | length) | add' "${OUT}.tmp")
  [[ "$STEPS" == "45" ]] || { echo "noctalia-sync: Hue-Skala unvollstaendig ($m: $STEPS/45 Steps)" >&2; exit 1; }
  ALIASES=$(jq -r --arg m "$m" '.[$m].hue | [.orange,.yellow,.green,.accent,.interactive,.neutral] | map(select(type == "string" and startswith("$hue."))) | length' "${OUT}.tmp")
  [[ "$ALIASES" == "6" ]] || { echo "noctalia-sync: Hue-Aliase unvollstaendig ($m: $ALIASES/6)" >&2; exit 1; }
done

mv "${OUT}.tmp" "$OUT"
echo "noctalia-sync: Quelle = $ZED ($SRC)"
jq -r '"refs dark=\(.dark.refs) light=\(.light.refs), alle Links OK"' <<<"$REPORT"
echo "noctalia-sync: geschrieben -> $OUT"
