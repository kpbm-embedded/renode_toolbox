# shellcheck shell=bash disable=SC2015,SC2034  # d_* return 0; TOOL_* are read by boxtool.bash
# renode-box: tool part (hooks for lib/boxtool.bash). Renode portable (dotnet bundled),
# xPack Arm and RISC-V GCC, FreeRTOS-Kernel, and a pixi env with Robot Framework + dts2repl.
TOOL_TITLE="32_06_renode: Renode $(sed -n 's/^renode\t\([^\t]*\)\t.*/\1/p' "${BOXT_ROOT:?}/config/pins.tsv" | head -1) (Antmicro) + Arm/RISC-V GCC + FreeRTOS"
TOOL_INSTALL_WHAT="the example firmware build (examples build)"
TOOL_HELP_USE="  renode [args]           Renode (GUI monitor; --console / --disable-gui for headless)
  robot <file.robot> [args]   renode-test (Robot Framework) on a test file
  repl <zephyr.dts> [-o F]    dts2repl: Renode platform (.repl) from a flattened DTS
  platforms [filter]      list the bundled platform .repl files (cpus/ and boards/)"
hook_help() { # printed after boxtool's help: tool-specific examples and environment
  cat <<EOF

tool examples
  ./$BOXT_NAME platforms stm32                  which .repl files exist for a chip family
  ./$BOXT_NAME renode --console --disable-gui   headless Renode monitor
  ./$BOXT_NAME repl board.dts -o board.repl     Renode platform from a flattened devicetree
  ./$BOXT_NAME robot my_test.robot --variable ELF:fw.elf   Robot Framework test on Renode
tool environment
  DISPLAY / WAYLAND_DISPLAY   the Renode GUI needs one; without, use --console --disable-gui
EOF
}
# shellcheck source-path=SCRIPTDIR source=boxtool.bash
. "$BOXT_ROOT/lib/boxtool.bash"

RENODE_DIR="$INST/renode"
renode_bin() { if [ -x "$RENODE_DIR/renode" ]; then printf '%s' "$RENODE_DIR/renode"; else printf '%s' "$RENODE_DIR/bin/Renode.exe"; fi; }

hook_env() {
  local p
  for p in "$INST/riscv-gcc/bin" "$INST/arm-gcc/bin" "$RENODE_DIR"; do
    [ -d "$p" ] && PATH="$p:$PATH"
  done
  export PATH
  RENODE=$(renode_bin)
  export RENODE RENODE_DIR FREERTOS_KERNEL="$INST/freertos" RENODE_BOX_DEMOS="$DL"
  export RENODE_BOX_ROOT="$ROOT" RENODE_BOX_EXAMPLES="$ROOT/examples"
  # Renode keeps its config (and the binaries cache for @https:// files) under the user
  # config dir; keep both inside this folder so nothing lands in ~/.config.
  export XDG_CONFIG_HOME="$ROOT/cache/xdg-config" XDG_CACHE_HOME="$ROOT/cache/xdg-cache"
  mkdir -p "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" 2>/dev/null || true
}

hook_bootstrap() { cachedir_tag "$ROOT/cache"; }

hook_install() { # demos-flag
  info "building the example firmware (examples build)"
  cmd_examples build
}

hook_status() {
  local e n=0
  for e in $(ex_list); do [ -d "$BUILD/examples/$e" ] && n=$((n+1)); done
  printf '  %-22s %s of %s built in %s\n' examples "$n" "$(ex_list | wc -l)" "$BUILD/examples"
}

hook_doctor() {
  local v
  if [ -x "$(renode_bin)" ]; then
    v=$("$(renode_bin)" --version 2>/dev/null | head -1) && d_ok "renode: $v" || d_fail "renode --version failed"
  else d_fail "renode missing in $RENODE_DIR"; fi
  [ -x "$RENODE_DIR/renode-test" ] && d_ok "renode-test present" || d_fail "renode-test missing"
  v=$(python -c 'import robot; print(robot.__version__)' 2>/dev/null) && d_ok "robotframework $v (renode wants 6.1)" || d_fail "robotframework missing in the pixi env"
  python -c 'import dts2repl' 2>/dev/null && d_ok "dts2repl importable" || d_fail "dts2repl missing"
  v=$(arm-none-eabi-gcc -dumpversion 2>/dev/null) && d_ok "arm-none-eabi-gcc $v ($(command -v arm-none-eabi-gcc | sed "s|$ROOT/||"))" || d_fail "arm-none-eabi-gcc missing"
  v=$(riscv-none-elf-gcc -dumpversion 2>/dev/null) && d_ok "riscv-none-elf-gcc $v" || d_fail "riscv-none-elf-gcc missing"
  v=$(make --version 2>/dev/null | head -1) && d_ok "$v" || d_fail "make missing"
  [ -r "$INST/freertos/include/FreeRTOS.h" ] && d_ok "FreeRTOS-Kernel $(pin_get freertos 2)" || d_fail "FreeRTOS-Kernel missing"
  local n miss=0
  for n in $(pin_names demo); do [ -f "$(pin_file "$n")" ] || miss=$((miss+1)); done
  [ "$miss" = 0 ] && d_ok "prebuilt demo binaries cached ($(pin_names demo | wc -l), offline)" || d_warn "$miss prebuilt demo binaries not cached (./$NAME install)"
  if [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; then d_ok "display present (Renode GUI/analyzers usable)"
  else d_warn "no display: use --console / --disable-gui (tests are headless anyway)"; fi
}

# native mode: Renode itself and renode-test/dts2repl through the launcher (they need the env python)
hook_native_bins() {
  echo "renode install/renode/renode"
  echo "renode-test @robot"
  echo "dts2repl @run dts2repl"
}

tool_cmd_renode() { activate; [ "$DRY" = 1 ] && { printf '+ renode %s\n' "$*"; return 0; }; exec "$(renode_bin)" "$@"; }
tool_cmd_robot() {
  activate
  [ "$DRY" = 1 ] && { printf '+ renode-test %s\n' "$*"; return 0; }
  mkdir -p "$LOG_DIR/robot"
  # renode-test writes robot_output.xml, log.html and snapshots to the cwd: absolute paths
  # for the test files, then run from the results dir
  local a args=()
  for a in "$@"; do
    if [ -e "$a" ] && [ "${a#/}" = "$a" ]; then args+=("$PWD/$a"); else args+=("$a"); fi
  done
  cd "$LOG_DIR/robot"
  exec "$RENODE_DIR/renode-test" --renode-config "$ROOT/cache/renode-config/config" -r "$LOG_DIR/robot" "${args[@]+"${args[@]}"}"
}
tool_cmd_repl() {
  [ $# -ge 1 ] || usage_error "usage: ./$NAME repl <zephyr.dts> [-o out.repl]"
  local dts=$1 outf=""; shift
  [ "${1:-}" = -o ] && outf=${2:?}
  activate
  [ "$DRY" = 1 ] && { printf '+ dts2repl %s\n' "$dts"; return 0; }
  if [ -n "$outf" ]; then dts2repl "$dts" -o "$outf"; info "wrote $outf"; else dts2repl "$dts" -o /dev/stdout; fi
}
tool_cmd_platforms() {
  local f=${1:-}
  (cd "$RENODE_DIR/platforms" && find cpus boards -name '*.repl' | sort | grep -i -- "$f")
}
# new board <name> --dts <zephyr.dts>: the platform comes from dts2repl instead of the stub
hook_new() { # kind name dst [args]
  local kind=$1 nm=$2 dst=$3; shift 3
  [ "$kind" = board ] || return 0
  local dts=""
  while [ $# -gt 0 ]; do
    case "$1" in --dts) dts=${2:?--dts needs a file}; shift ;; *) usage_error "new board: unknown option $1" ;; esac; shift
  done
  [ -n "$dts" ] || return 0
  [ -r "$dts" ] || die "no such DTS: $dts"
  activate
  dts2repl "$dts" -o "$dst/$nm.repl" 2> >(grep -v 'Skipping duplicated block' >&2)
  info "platform $dst/$nm.repl generated from $dts (dts2repl)"
}

boxt_main "$@"
