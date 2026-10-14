#!/usr/bin/env bash
# tests/test-tui-frame.sh — regression: wizard first frame visible, waits, exits on action.
set -u
cd "$(dirname "$0")/.." || exit 1
command -v python3 >/dev/null || { echo "SKIP: python3 missing"; exit 0; }
H=$(sha256sum nix/machine/local.nix | cut -d' ' -f1)
out=$(python3 - <<'EOF'
import pty, os, subprocess, time, termios, struct, fcntl, re
m, s = pty.openpty()
fcntl.ioctl(s, termios.TIOCSWINSZ, struct.pack("HHHH", 24, 80, 0, 0))
p = subprocess.Popen(["setsid","bash","-c","./scripts/install-wizard.sh --dry-run <&0 >&0 2>&0; echo WIZARD-RC=$?"],
    stdin=s, stdout=s, stderr=s, close_fds=True, env={**os.environ,"TERM":"xterm-256color"})
os.close(s)
fcntl.fcntl(m, fcntl.F_SETFL, os.O_NONBLOCK)
def drain(buf):
    try:
        while True:
            try: c=os.read(m,65536)
            except BlockingIOError: break
            except OSError: break
            if not c: break
            buf+=c
    except Exception: pass
    return buf
time.sleep(1.2); out=drain(b""); first=bytes(out)
alive1 = p.poll() is None
for k in [b"\n", b"\n", b"\n", b"\x1b[B", b"\n"]:
    try: os.write(m, k)
    except OSError: pass
    time.sleep(0.7); out=drain(out)
for _ in range(10):
    if b"WIZARD-RC=" in out: break
    time.sleep(0.5); out=drain(out)
try: p.wait(timeout=3)
except Exception:
    try: p.terminate(); p.wait(timeout=2)
    except Exception:
        try: p.kill()
        except Exception: pass
os.close(m)
tf = re.sub(rb"\x1b\[[0-9;?]*[a-zA-Z]", b"", first).decode("utf-8","replace")
t = re.sub(rb"\x1b\[[0-9;?]*[a-zA-Z]", b"", out).decode("utf-8","replace")
ok = True
def check(name, cond):
    global ok
    print(("ok" if cond else "FAIL"), name)
    if not cond: ok = False
check("first frame visible", "DOTFILES SETUP" in tf and "Enter continue" in tf and "Keyboard" in tf)
check("waits for input (alive at 1.2s)", alive1)
check("alt-screen entered once per step", out.count(b"[?1049h") >= 4)
check("alt-screen balanced", out.count(b"[?1049h") == out.count(b"[?1049l"))
check("exits after action", "WIZARD-RC=" in t)
print("RESULT", "PASS" if ok else "FAIL")
EOF
)
echo "$out"
echo "$out" | grep -q "^RESULT PASS" || { echo "tui-frame: FAIL"; exit 1; }
H2=$(sha256sum nix/machine/local.nix | cut -d' ' -f1)
[[ "$H" == "$H2" ]] || { echo "tui-frame: FAIL (local.nix changed)"; exit 1; }
echo "tui-frame: PASS (dry-run side-effect free)"
