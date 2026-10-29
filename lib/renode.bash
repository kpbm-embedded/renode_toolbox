# shellcheck shell=bash disable=SC2015,SC2034  # d_* return 0; TOOL_* are read by boxtool.bash
# renode-box: tool part (hooks for lib/boxtool.bash). Renode portable (dotnet bundled),
# xPack Arm and RISC-V GCC, FreeRTOS-Kernel, and a pixi env with Robot Framework + dts2repl.
TOOL_TITLE="32_06_renode: Renode $(sed -n 's/^renode\t\([^\t]*\)\t.*/\1/p' "${BOXT_ROOT:?}/config/pins.tsv" | head -1) (Antmicro) + Arm/RISC-V GCC + FreeRTOS"
TOOL_INSTALL_WHAT="the example firmware build (examples build)"
TOOL_HELP_USE="  renode [args]           Renode (GUI monitor; --console / --disable-gui for headless)
  robot <file.robot> [args]   renode-test (Robot Framework) on a test file
  repl <zephyr.dts> [-o F]    dts2repl: Renode platform (.repl) from a flattened DTS
  platforms [filter]      list the bundled platform .repl files (cpus/ and boards/)
  ui [renode args]        experimental GUI (renode --ui: Monitor, Logs, UART, Sensors panes; needs a display)
  server [--port N] [--work-dir D]   server mode: WebSocket API at ws://<host>:N/proxy (default 21234)
  retrace <args>          renode-retracer (tools/execution_tracer): binary trace -> LCOV .info / Coverview zip
  covflow <cmd> [args]    coverage flow (lib/covflow.py): info | merge | summary | pack | html (help: covflow -h)
  extras [list|install <name>...]   optional pinned add-ons: coverview, renode-rdl, jdk, gradle, ghidra, girdl
  ghidra <analyzeHeadless args>     Ghidra 12.2 headless with the pinned JDK 25 (extras install ghidra jdk)
  girdl <args>            girdl standalone (java -jar girdl.jar): RDL/SVD + peripheral map -> DWARF"
hook_help() { # printed after boxtool's help: tool-specific examples and environment
  cat <<EOF

tool examples
  ./$BOXT_NAME platforms stm32                  which .repl files exist for a chip family
  ./$BOXT_NAME renode --console --disable-gui   headless Renode monitor
  ./$BOXT_NAME repl board.dts -o board.repl     Renode platform from a flattened devicetree
  ./$BOXT_NAME robot my_test.robot --variable ELF:fw.elf   Robot Framework test on Renode
  ./$BOXT_NAME server --port 21234             WebSocket API for System Designer / the VS Code extension
  ./$BOXT_NAME covflow summary run.info         line coverage per file from a retracer .info
tool environment
  DISPLAY / WAYLAND_DISPLAY   the Renode GUI and \`ui\` need one; without, use --console --disable-gui or \`server\`
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
  doctor_ui_server
  [ -r "$RENODE_DIR/tools/execution_tracer/execution_tracer_reader.py" ] && d_ok "renode-retracer (tools/execution_tracer) present" || d_fail "tools/execution_tracer missing"
  v=$(python -c 'import importlib.metadata as m; print(m.version("info-process"))' 2>/dev/null) && d_ok "info-process $v (coverage merge/pack)" || d_fail "info-process missing in the pixi env"
  local x got=""
  for x in $(pin_names optional); do if pin_installed "$x"; then got="$got $x"; fi; done
  d_ok "optional add-ons installed:${got:- none} (./$NAME extras list)"
}

# --ui: Renode 1.17 ships the Neutralino app (github.com/antmicro/renode-ui, Apache-2.0) as
# platform-lib/<platform>/renode-ui; it needs GTK3 + WebKitGTK 4.1 from the system and talks to Renode over the
# server-mode WebSocket API (always port 21234 with --ui). --server-mode alone: the same API, headless.
renode_ui_bin() { find -L "$RENODE_DIR/platform-lib" -mindepth 2 -maxdepth 2 -name renode-ui -type f 2>/dev/null | head -1; }
doctor_ui_server() {
  local ui miss port log pid i ok=0
  ui=$(renode_ui_bin)
  if [ -z "$ui" ]; then d_warn "renode-ui not in this Renode package (\`ui\` unavailable)"
  else
    miss=$(ldd "$ui" 2>/dev/null | awk '/not found/ {print $1}' | tr '\n' ' ')
    if [ -n "$miss" ]; then d_warn "renode-ui: missing system libraries: $miss(install GTK3 + WebKitGTK 4.1 for --ui)"
    elif ! { ldconfig -p 2>/dev/null | grep 'libwebkit2gtk-4\.[01]' >/dev/null || ls /usr/lib*/libwebkit2gtk-4.1.so* /usr/lib/*/libwebkit2gtk-4.1.so* >/dev/null 2>&1; }; then
      d_warn "renode-ui present, WebKitGTK 4.1 not found (needed by --ui)"
    else d_ok "renode-ui present (${ui#"$RENODE_DIR"/}; GTK3/WebKitGTK found; needs a display)"; fi
  fi
  port=$(python -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1",0)); print(s.getsockname()[1])' 2>/dev/null) || { d_warn "server mode not checked (no python)"; return 0; }
  log=$(mktemp "${TMPDIR:-/tmp}/rbox-srv.XXXXXX")
  "$(renode_bin)" --server-mode --server-mode-port "$port" --config "$ROOT/cache/renode-config/config" --plain </dev/null >"$log" 2>&1 &
  pid=$!
  for ((i = 0; i < 120; i++)); do
    if python "$ROOT/lib/ws_client.py" --port "$port" --timeout 5 status >/dev/null 2>&1; then ok=1; break; fi
    kill -0 "$pid" 2>/dev/null || break; sleep 0.25
  done
  kill "$pid" 2>/dev/null; wait "$pid" 2>/dev/null
  rm -f "$log"
  [ "$ok" = 1 ] && d_ok "server mode: WebSocket API answers (protocol 1.5.0, port $port)" || d_fail "server mode: no WebSocket answer on port $port"
}

# native mode: Renode itself and renode-test/dts2repl through the launcher (they need the env python)
hook_native_bins() {
  echo "renode install/renode/renode"
  echo "renode-test @robot"
  echo "dts2repl @run dts2repl"
}

tool_cmd_ui() { # experimental Neutralino GUI: renode --ui starts renode-ui and serves the API on 21234 (fixed with --ui)
  activate
  [ -n "$(renode_ui_bin)" ] || die "ui: renode-ui is not part of this Renode package ($RENODE_DIR/platform-lib/*/renode-ui)"
  [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ] || { [ "$DRY" = 1 ] || not_applicable "ui needs a display (DISPLAY or WAYLAND_DISPLAY); headless: ./$NAME server"; }
  [ "$DRY" = 1 ] && { printf '+ renode --ui %s\n' "$*"; return 0; }
  if (exec 3<>/dev/tcp/127.0.0.1/21234) 2>/dev/null; then die "ui: port 21234 is in use (renode --ui always serves on it): stop the other Renode server first"; fi
  warn "renode --ui serves the WebSocket API on all interfaces (0.0.0.0:21234): firewall it on untrusted networks"
  exec "$(renode_bin)" --ui --config "$ROOT/cache/renode-config/config" "$@"
}
tool_cmd_server() { # server mode: WebSocket API (System Designer "Run locally", VS Code extension, renode-ui)
  local port=21234 wd="" a=()
  while [ $# -gt 0 ]; do
    case "$1" in --port) port=${2:?--port needs a number}; shift ;; --work-dir) wd=${2:?}; shift ;; *) a+=("$1") ;; esac; shift
  done
  activate
  warn "Renode 1.17 server mode listens on all interfaces (0.0.0.0:$port), there is no bind option: keep the port behind a firewall on untrusted networks"
  [ "$DRY" = 1 ] && { printf '+ renode --server-mode --server-mode-port %s%s %s\n' "$port" "${wd:+ --server-mode-work-dir $wd}" "${a[*]+"${a[*]}"}"; return 0; }
  info "WebSocket API: ws://localhost:$port/proxy (protocol 1.5.0; client: lib/ws_client.py)"
  exec "$(renode_bin)" --server-mode --server-mode-port "$port" ${wd:+--server-mode-work-dir "$wd"} --config "$ROOT/cache/renode-config/config" "${a[@]+"${a[@]}"}"
}
tool_cmd_retrace() { # renode-retracer from the Renode package (needs only pyelftools 0.30, in the env)
  activate
  [ "$DRY" = 1 ] && { printf '+ renode-retracer %s\n' "$*"; return 0; }
  exec python "$RENODE_DIR/tools/execution_tracer/execution_tracer_reader.py" "$@"
}
tool_cmd_covflow() {
  activate
  [ "$DRY" = 1 ] && { printf '+ covflow %s\n' "$*"; return 0; }
  exec python "$ROOT/lib/covflow.py" "$@"
}
# optional add-ons from config/pins.tsv (group optional): unpacked to install/<name>; girdl is built after unpacking
tool_cmd_extras() {
  local sub=${1:-list}; [ $# -gt 0 ] && shift
  case "$sub" in
    list)
      local n
      for n in $(pin_names optional); do
        printf '  %-11s %-28s %s\n' "$n" "$(pin_get "$n" 2)" "$( [ -z "$(pin_line "$n")" ] && echo "no pin for $PLATFORM" || { pin_installed "$n" && echo "installed ($(human_size "$(pin_dir "$n")"))" || echo "not installed"; })"
      done ;;
    install)
      [ $# -gt 0 ] || usage_error "usage: ./$NAME extras install <name>... (names: $(pin_names optional | tr '\n' ' '))"
      local n
      for n in "$@"; do
        pin_names optional | grep -qx -- "$n" || usage_error "no optional add-on '$n' (./$NAME extras list)"
        case "$n" in girdl) install_pin jdk; install_pin gradle; install_pin ghidra ;; ghidra) install_pin jdk ;; esac
        install_pin "$n"
      done ;;
    *) usage_error "usage: ./$NAME extras list | install <name>..." ;;
  esac
}
hook_post_install_pin() { # name dir
  [ "$1" = girdl ] || return 0
  local d=$2
  info "building girdl against Ghidra $(pin_get ghidra 2) (gradle $(pin_get gradle 2), JDK $(pin_get jdk 2); Maven deps -> cache/gradle-home)"
  mkdir -p "$d/ghidra" && ln -sfn "$INST/ghidra" "$d/ghidra/install"
  (cd "$d" && JAVA_HOME="$INST/jdk" GRADLE_USER_HOME="$ROOT/cache/gradle-home" \
     "$INST/gradle/bin/gradle" --no-daemon -q buildExtension) || return 1
  local z; z=$(find "$d/dist" -maxdepth 1 -name '*.zip' 2>/dev/null | head -1)
  [ -n "$z" ] || { warn "girdl: no dist/*.zip after the build"; return 1; }
  (cd "$d/dist" && python3 -I -m zipfile -e "$z" .) && info "girdl built: ${z#"$ROOT"/}"
}
girdl_jar() { local j=$INST/girdl/dist/girdl/lib/girdl.jar; [ -f "$j" ] && printf '%s' "$j"; true; }
ghidra_settings_dir() { # Ghidra's settings dir under XDG_CONFIG_HOME (cache/xdg-config); outside $HOME it is "<user>-ghidra"
  local p=$INST/ghidra/Ghidra/application.properties v r
  v=$(sed -n 's/^application.version=//p' "$p"); r=$(sed -n 's/^application.release.name=//p' "$p")
  printf '%s/%s-ghidra/ghidra_%s_%s' "$XDG_CONFIG_HOME" "$(id -un)" "$v" "$r"
}
tool_cmd_ghidra() { # analyzeHeadless with the pinned JDK; settings in cache/xdg-config; girdl loaded when built
  pin_installed ghidra && pin_installed jdk || { [ "$DRY" = 1 ] || not_applicable "Ghidra is optional: ./$NAME extras install ghidra"; }
  [ "$DRY" = 1 ] && { printf '+ analyzeHeadless %s\n' "$*"; return 0; }
  activate
  local ext
  if [ -n "$(girdl_jar)" ]; then   # user extension = the unpacked girdl.zip (what File > Install Extensions does)
    ext="$(ghidra_settings_dir)/Extensions"
    mkdir -p "$ext" && ln -sfn "$INST/girdl/dist/girdl" "$ext/girdl"
  fi
  JAVA_HOME="$INST/jdk" PATH="$INST/jdk/bin:$PATH" exec "$INST/ghidra/support/analyzeHeadless" "$@"
}
tool_cmd_girdl() {
  [ -n "$(girdl_jar)" ] || { [ "$DRY" = 1 ] || not_applicable "girdl is optional: ./$NAME extras install girdl"; }
  [ "$DRY" = 1 ] && { printf '+ java -jar girdl.jar %s\n' "$*"; return 0; }
  exec "$INST/jdk/bin/java" -jar "$(girdl_jar)" "$@"
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
