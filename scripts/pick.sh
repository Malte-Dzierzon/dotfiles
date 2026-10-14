#!/usr/bin/env bash
# scripts/pick.sh — fullscreen alt-screen picker (sourced, never executed).
# Fixed frame: header (title + step rail), content area, fixed footer.
# Alt-screen (\033[?1049h/l), cursor hidden, restored via trap incl. INT/TERM.
# Backends: this picker on TTY; numbered fallback for pipes/dumb.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "XX pick.sh is sourced, not executed." >&2
  exit 1
fi

__PICK_DIM='' __PICK_X='' __PICK_ACC='' __PICK_REV='' __PICK_B=''
[[ "${TERM:-dumb}" != "dumb" && -z "${NO_COLOR:-}" ]] && {
  __PICK_DIM=$'\033[2m'; __PICK_X=$'\033[0m'; __PICK_ACC=$'\033[1;36m'
  __PICK_REV=$'\033[7m'; __PICK_B=$'\033[1m'
}

__PICK_INIT=0 __PICK_UTF=0
_pick_init() {
  [[ $__PICK_INIT -eq 1 ]] && return 0
  __PICK_INIT=1
  [[ "${TERM:-dumb}" != "dumb" && -z "${NO_COLOR:-}" ]] || return 0
  [[ "$(locale charmap 2>/dev/null)" == "UTF-8" ]] && __PICK_UTF=1
  return 0
}
_pick_glyph() {
  _pick_init
  case "$1" in
    ptr) [[ $__PICK_UTF -eq 1 ]] && printf '>' || printf '>' ;;
    on) [[ $__PICK_UTF -eq 1 ]] && printf '[x]' || printf '[x]' ;;
    off) printf '[ ]' ;;
    lock) [[ $__PICK_UTF -eq 1 ]] && printf '[=]' || printf '[=]' ;;
    done) [[ $__PICK_UTF -eq 1 ]] && printf 'ok' || printf 'ok' ;;
  esac
}

# Frame state (set by _frame_enter, used by _frame_draw).
_PR_TITLE="" _PR_FOOT="" _PR_STEPS="" _PR_INFO=""
_PR_DESC=() _PR_LOCK=() _PR_ON=()

_frame_enter() {
  printf '\033[?1049h\033[?25l\033[H\033[2J' >&2
  trap 'printf "\033[?25h\033[?1049l" >&2' INT TERM EXIT
}
_frame_leave() {
  printf '\033[?25h\033[?1049l' >&2
  trap - INT TERM EXIT
}

# _frame_draw <mode> <idx> <scroll> <opts...>: full redraw via absolute cursor.
_frame_draw() {
  local mode="$1" idx="$2" scroll="$3"
  shift 3
  local opts=("$@")
  local rows cols
  rows=$(tput lines 2>/dev/null || echo 24); cols=$(tput cols 2>/dev/null || echo 80)
  [[ "$rows" =~ ^[0-9]+$ ]] || rows=24
  [[ "$cols" =~ ^[0-9]+$ ]] || cols=80
  ((rows < 10)) && rows=10
  local out="" i ptr mark line d
  # header row 1-2
  out+=$'\033[H\033[2J'
  out+="${__PICK_B} DOTFILES SETUP${__PICK_X}"
  [[ -n "$_PR_INFO" ]] && out+="${__PICK_DIM}  ${_PR_INFO}${__PICK_X}"
  out+=$'\n'
  if [[ -n "$_PR_STEPS" ]]; then
    out+="${__PICK_DIM}${_PR_STEPS}${__PICK_X}"$'\n'
  else
    out+="${__PICK_DIM}${_PR_TITLE}${__PICK_X}"$'\n'
  fi
  # content: rows 3..rows-2
  local maxlines=$((rows - 4))
  ((maxlines < 3)) && maxlines=3
  local n=${#opts[@]} start=$scroll end=$((scroll + maxlines))
  ((end > n)) && end=$n
  for ((i = start; i < end; i++)); do
    if [[ $i -eq $idx ]]; then ptr=">"; else ptr=" "; fi
    if [[ "$mode" == "multi" ]]; then
      if [[ "${_PR_LOCK[$i]:-0}" == "1" ]]; then mark="[=]"
      elif [[ "${_PR_ON[$i]:-0}" == "1" ]]; then mark="[x]"
      else mark="[ ]"; fi
      line=$(printf ' %s %s %s' "$ptr" "$mark" "${opts[$i]}")
    else
      line=$(printf ' %s %s' "$ptr" "${opts[$i]}")
    fi
    d="${_PR_DESC[$i]:-}"
    [[ -n "$d" ]] && line+=$(printf '  %s%s%s' "${__PICK_DIM}" "$d" "${__PICK_X}")
    if [[ $i -eq $idx ]]; then
      out+="${__PICK_REV}${line}${__PICK_X}"$'\033[K'$'\n'
    else
      out+="${line}"$'\033[K'$'\n'
    fi
  done
  if ((n > maxlines)); then
    out+="${__PICK_DIM}  … $((idx + 1))/$n${__PICK_X}"$'\033[K'$'\n'
  fi
  # fixed footer: last row
  out+=$(printf '\033[%s;1H' "$rows")
  out+="${__PICK_DIM}${_PR_FOOT}${__PICK_X}"$'\033[K'
  printf '%s' "$out" >&2
  _PR_MAXLINES=$maxlines
}

_pick_readkey() {
  local b rest
  IFS= read -rsn1 b </dev/tty 2>/dev/null || { printf 'EXIT'; return; }
  [[ "$b" == $'\x1b' ]] || {
    [[ -z "$b" ]] && { printf 'ENTER'; return; }
    [[ "$b" == " " ]] && { printf 'SPACE'; return; }
    [[ "$b" == $'\x03' || "$b" == $'\x04' ]] && { printf 'EXIT'; return; }
    printf 'CHAR:%s' "$b"
    return
  }
  if IFS= read -rsn1 -t 0.06 rest </dev/tty 2>/dev/null; then
    b+="$rest"
    if [[ "$rest" == "[" || "$rest" == "O" ]]; then
      IFS= read -rsn1 -t 0.06 rest </dev/tty 2>/dev/null && b+="$rest"
    fi
  else
    printf 'ESC'
    return
  fi
  case "$b" in
    $'\x1b[A' | $'\x1bOA') printf 'UP' ;;
    $'\x1b[B' | $'\x1bOB') printf 'DOWN' ;;
    *) printf 'ESC' ;;
  esac
}

# _pick_loop <mode> <startidx> <opts...>
_pick_loop() {
  local mode="$1" idx="$2"
  shift 2
  local opts=("$@") key i out="" scroll=0
  _frame_enter
  while true; do
    local maxl
    maxl=$(tput lines 2>/dev/null || echo 24); maxl=$((maxl - 4))
    ((maxl < 3)) && maxl=3
    ((idx < scroll)) && scroll=$idx
    ((idx >= scroll + maxl)) && scroll=$((idx - maxl + 1))
    _frame_draw "$mode" "$idx" "$scroll" "${opts[@]}"
    key="$(_pick_readkey)"
    case "$key" in
      UP) idx=$(((idx - 1 + ${#opts[@]}) % ${#opts[@]})) ;;
      DOWN) idx=$(((idx + 1) % ${#opts[@]})) ;;
      SPACE)
        if [[ "$mode" == "multi" && "${_PR_LOCK[$idx]:-0}" != "1" ]]; then
          if [[ "${_PR_ON[$idx]:-0}" == "1" ]]; then _PR_ON[$idx]=0; else _PR_ON[$idx]=1; fi
        fi
        ;;
      ENTER)
        _frame_leave
        if [[ "$mode" == "multi" ]]; then
          for i in "${!opts[@]}"; do [[ "${_PR_ON[$i]:-0}" == "1" ]] && out+="${opts[$i]},"; done
          printf '%s' "${out%,}"
        else
          printf '%s' "${opts[$idx]}"
        fi
        return 0
        ;;
      ESC | EXIT)
        _frame_leave
        printf '\n' >&2
        return 1
        ;;
      CHAR:/) ;;
    esac
  done
}

_set_descs() {
  _PR_DESC=()
  local i
  for i in "${!_all_opts[@]}"; do _PR_DESC[$i]=''; done
  if [[ -n "${PICK_DESCS:-}" ]]; then
    local _d=()
    IFS=';' read -ra _d <<<"$PICK_DESCS"
    for i in "${!_d[@]}"; do _PR_DESC[$i]="${_d[$i]}"; done
  fi
}

pick_single() {
  local title="$1" foot="$2" def="$3"
  shift 3
  local opts=("$@") i=0
  _PR_TITLE="$title" _PR_FOOT="$foot"
  _PR_DESC=(); _PR_LOCK=(); _PR_ON=()
  _all_opts=("${opts[@]}"); _set_descs
  for i in "${!opts[@]}"; do _PR_LOCK[$i]=0; _PR_ON[$i]=0; done
  local found=0
  for i in "${!opts[@]}"; do [[ "${opts[$i]}" == "$def" ]] && { found=1; break; }; done
  if [[ $found -eq 0 ]]; then
    for i in "${!opts[@]}"; do [[ "${opts[$i]}" == "$def"* ]] && { found=1; break; }; done
  fi
  [[ $found -eq 0 ]] && i=0
  [[ -t 0 && -e /dev/tty && "${TERM:-dumb}" != "dumb" ]] || { printf '%s' "$def"; return 0; }
  _pick_loop single "$i" "${opts[@]}"
}

pick_multi() {
  local title="$1" foot="$2" pre="$3"
  shift 3
  local opts=("$@") i=0
  _PR_TITLE="$title" _PR_FOOT="$foot"
  _PR_DESC=(); _PR_LOCK=(); _PR_ON=()
  _all_opts=("${opts[@]}"); _set_descs
  for i in "${!opts[@]}"; do
    _PR_LOCK[$i]=0; _PR_ON[$i]=0
    [[ ",$pre," == *",${opts[$i]},"* ]] && _PR_ON[$i]=1
    [[ ",${PICK_LOCKS:-}," == *",${opts[$i]},"* ]] && { _PR_ON[$i]=1; _PR_LOCK[$i]=1; }
  done
  [[ -t 0 && -e /dev/tty && "${TERM:-dumb}" != "dumb" ]] || { printf '%s' "$pre"; return 0; }
  _pick_loop multi 0 "${opts[@]}"
}

pick_filter() {
  local title="$1" foot="$2" def="$3"
  shift 3
  local all=("$@") filt="" f=() i=0 key b
  [[ -t 0 && -e /dev/tty && "${TERM:-dumb}" != "dumb" ]] || { printf '%s' "$def"; return 0; }
  _frame_enter
  local scroll=0 _PR_BASE_INFO="$_PR_INFO"
  while true; do
    f=()
    for b in "${all[@]}"; do [[ "${b,,}" == *"${filt,,}"* ]] && f+=("$b"); done
    [[ ${#f[@]} -eq 0 ]] && f=("(no match)")
    ((i >= ${#f[@]})) && i=0
    ((i < scroll)) && scroll=$i
    _PR_TITLE="$title" _PR_FOOT="$foot"
    _PR_DESC=(); _PR_LOCK=(); _PR_ON=()
    _all_opts=("${f[@]}"); _set_descs
    _PR_INFO="${_PR_BASE_INFO:+$_PR_BASE_INFO · }filter: ${filt:-—}"
    _frame_draw single "$i" "$scroll" "${f[@]}"
    key="$(_pick_readkey)"
    case "$key" in
      UP) i=$(((i - 1 + ${#f[@]}) % ${#f[@]})) ;;
      DOWN) i=$(((i + 1) % ${#f[@]})) ;;
      ENTER)
        _frame_leave
        [[ "${f[$i]}" == "(no match)" ]] && return 1
        printf '%s' "${f[$i]}"
        return 0
        ;;
      ESC | EXIT) _frame_leave; printf '\n' >&2; return 1 ;;
      CHAR:*)
        b="${key#CHAR:}"
        if [[ "$b" == $'\x7f' ]]; then filt="${filt%?}"
        elif [[ "$b" =~ ^[a-zA-Z0-9_+@-]$ ]]; then filt+="$b"; i=0; scroll=0; fi
        ;;
    esac
  done
}
