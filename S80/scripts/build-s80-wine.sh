#!/usr/bin/env bash
# Build X-plore for the Nokia 9500 with the native Windows S80 DP 2.0 SDK
# running under Wine. Same Wine prefix and SDK as Commlink.
#
#   scripts/build-s80-wine.sh check   # verify prefix, Perl, SDK, toolchain
#   scripts/build-s80-wine.sh build   # bldmake + abld armi urel + makesis
#   scripts/build-s80-wine.sh clean   # abld reallyclean + remove staging
#   scripts/build-s80-wine.sh shell   # wine cmd with the SDK environment set
#
# Environment overrides:
#   WINEPREFIX   default ~/.wine (32- or 64-bit prefix both work)
#   S80_SDK      Linux path of the SDK root (the dir containing epoc32/);
#                auto-detected under $WINEPREFIX/drive_c/Symbian if unset
#   S80_TARGET   default armi (armi | thumb | arm4)
#   S80_VARIANT  default urel (urel | udeb)
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export WINEPREFIX="${WINEPREFIX:-$HOME/.wine}"
export WINEDEBUG="${WINEDEBUG:--all}"
target="${S80_TARGET:-armi}"
variant="${S80_VARIANT:-urel}"
drive_c="$WINEPREFIX/drive_c"
proj_link="$drive_c/xplore"     # project must be on the same drive as epoc32
stage="$root/S80/sis"

die() { printf 'error: %s\n' "$*" >&2; exit 1; }

find_sdk() {
  if [ -n "${S80_SDK:-}" ]; then
    printf '%s\n' "$S80_SDK"; return
  fi
  # Typical: drive_c/Symbian/7.0s/S80_DP2_0_SDK[_CW]/epoc32
  local hit
  hit="$(find "$drive_c/Symbian" -maxdepth 3 -type d -iname epoc32 2>/dev/null | sort | head -n1 || true)"
  [ -n "$hit" ] && dirname "$hit"
}

# /home/.../drive_c/Symbian/7.0s/X  ->  \Symbian\7.0s\X
to_dos_rel() {
  local rel="${1#"$drive_c"}"
  printf '%s' "${rel//\//\\}"
}

sdk="$(find_sdk || true)"

ensure_prefix() {
  command -v wine >/dev/null || die "wine not found"
  [ -d "$drive_c" ] || die "no Wine prefix at $WINEPREFIX (run wineboot -i)"
}

ensure_sdk() {
  [ -n "$sdk" ] && [ -d "$sdk/epoc32" ] \
    || die "S80 SDK not found under $drive_c/Symbian (set S80_SDK=...)"
  case "$sdk" in "$drive_c"/*) ;; *) die "S80_SDK must be inside $drive_c";; esac
}

ensure_link() {
  if [ -L "$proj_link" ]; then
    [ "$(readlink -f "$proj_link")" = "$root" ] \
      || die "$proj_link points elsewhere; remove it first"
  elif [ -e "$proj_link" ]; then
    die "$proj_link exists and is not a symlink"
  else
    ln -s "$root" "$proj_link"
  fi
}

# Writes a batch file that sets EPOCROOT/PATH, then runs "$@" in S80\.
run_in_sdk() {
  local sdk_dos epocroot bat
  sdk_dos="C:$(to_dos_rel "$sdk")"
  epocroot="$(to_dos_rel "$sdk")\\"
  bat="$root/S80/.wine-build.bat"
  {
    printf '@echo off\r\n'
    printf 'set EPOCROOT=%s\r\n' "$epocroot"
    printf 'set PATH=C:\\Perl\\bin;%s\\epoc32\\gcc\\bin;%s\\epoc32\\tools;%%PATH%%\r\n' \
      "$sdk_dos" "$sdk_dos"
    printf 'cd /d C:\\xplore\\S80\r\n'
    for cmd in "$@"; do
      printf '%s\r\n' "$cmd"
      [ "$cmd" = cmd ] || printf 'if errorlevel 1 exit /b 1\r\n'
    done
  } > "$bat"
  local rc=0
  wine cmd /c 'C:\xplore\S80\.wine-build.bat' || rc=$?
  rm -f "$bat"
  return $rc
}

ok()      { printf 'ok       %s\n' "$*"; }
missing() { printf 'MISSING  %s\n' "$*"; bad=1; }

cmd_check() {
  bad=0
  command -v wine >/dev/null && ok "wine $(wine --version)" || missing "wine"
  if [ -d "$drive_c" ]; then
    ok "prefix $WINEPREFIX"
  else
    missing "prefix $WINEPREFIX"
  fi
  [ -f "$drive_c/Perl/bin/perl.exe" ] && ok "C:\\Perl\\bin\\perl.exe" \
    || missing "ActivePerl 5.6.1 in C:\\Perl"
  if [ -n "$sdk" ] && [ -d "$sdk/epoc32" ]; then
    ok "SDK $sdk"
    local e="$sdk/epoc32"
    for f in tools/bldmake.bat tools/makesis.exe tools/rcomp.exe \
             include/eikon.rh include/eikedwin.h release/$target/$variant/euser.lib; do
      [ -n "$(find "$e" -ipath "$e/$f" 2>/dev/null | head -n1)" ] \
        && ok "epoc32/$f" || missing "epoc32/$f"
    done
    [ -f "$e/gcc/bin/gcc.exe" ] \
      && ok "epoc32/gcc/bin/gcc.exe (GCC 2.9 ARM toolchain)" || missing "epoc32/gcc/bin/gcc.exe"
  else
    missing "S80 DP 2.0 SDK under $drive_c/Symbian"
  fi
  return "$bad"
}

cmd_build() {
  ensure_prefix; ensure_sdk; ensure_link
  # abld does not reliably return an error code, so scan its output:
  # otherwise a failed compile would silently package the previous binary.
  local log="$root/S80/.wine-build.log"
  run_in_sdk "call bldmake bldfiles" "call abld build ${ABLD_OPTS:-} $target $variant ${S80_ONLY:-}" 2>&1 | tee "$log"
  if grep -qE '\*\*\* .*Error [0-9]|: error|undeclared|ERROR:' "$log"; then
    grep -E '\*\*\* .*Error [0-9]|: error|: `|undeclared|ERROR:|warning:' "$log" | head -n 40 >&2
    die "compile failed (full log: $log)"
  fi

  [ -n "${S80_ONLY:-}" ] && return
  python3 "$root/S80/scripts/make-data.py" "$root" "$stage/Data.dta"
  package xplore "$root/S80/data/xplore.rss"
}

# package <name> <rss>: copies the build output next to <name>.pkg and runs
# makesis, giving sis/<name>.sis.
package() {
  local name="$1" rss_src="$2" app rsc aif
  app="$(find "$sdk/epoc32/release" -ipath "*/$target/$variant/$name.app" | head -n1)"
  rsc="$(find "$sdk/epoc32" -iname "$name.rsc" -newer "$rss_src" 2>/dev/null | head -n1)"
  [ -z "$rsc" ] && rsc="$(find "$sdk/epoc32" -iname "$name.rsc" | head -n1)"
  [ -n "$app" ] || die "build finished but $name.app not found under epoc32/release/$target/$variant"
  [ -n "$rsc" ] || die "build finished but $name.rsc not found under epoc32"

  mkdir -p "$stage"
  cp "$app" "$rsc" "$root/S80/$name.pkg" "$stage/"
  aif="$(find "$sdk/epoc32" -iname "$name.aif" | head -n1)"
  [ -n "$aif" ] && cp "$aif" "$stage/"

  # The 7.0s makesis silently writes an empty SIS for LF-only .pkg files.
  sed -i 's/\r*$/\r/' "$stage/$name.pkg"
  rm -f "$stage/$name.sis"
  run_in_sdk "cd sis" "makesis $name.pkg $name.sis"
  local size; size=$(stat -c %s "$stage/$name.sis" 2>/dev/null || echo 0)
  [ "$size" -gt 1000 ] || die "makesis produced an empty package ($size bytes)"
  printf '\nSIS: %s (%s bytes)\n' "$stage/$name.sis" "$size"
}

cmd_clean() {
  ensure_prefix; ensure_sdk; ensure_link
  run_in_sdk "call bldmake bldfiles" "call abld reallyclean $target $variant" || true
  rm -rf "$stage" "$root/S80/ABLD.BAT"
}

cmd_shell() {
  ensure_prefix; ensure_sdk; ensure_link
  run_in_sdk cmd
}

case "${1:-build}" in
  check) cmd_check ;;
  build) cmd_build ;;
  clean) cmd_clean ;;
  shell) cmd_shell ;;
  *) die "usage: $0 [check|build|clean|shell]" ;;
esac
