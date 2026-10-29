# shellcheck shell=bash
# ex.sh: helpers sourced by examples/*/example.sh (run through ./renode-box examples ...,
# which puts Renode and the toolchains on PATH and sets EX_DIR, EX_OUT, RENODE_DIR).
set -euo pipefail
: "${EX_DIR:?run through ./renode-box examples}" "${EX_OUT:?}" "${RENODE_DIR:?}"
FW_DIR=$(cd "$EX_DIR/../fw" && pwd -P)
RENODE_CONFIG="${RENODE_BOX_ROOT:?}/cache/renode-config/config"
mkdir -p "$(dirname "$RENODE_CONFIG")"

ex_make() { # [make args]
  make --no-print-directory -C "$EX_DIR" -j"${BOXT_JOBS:-4}" FW="$FW_DIR" OUT="$EX_OUT" "$@"
}

# Interactive run: GUI monitor + UART analyzers when a display exists, else console.
ex_renode() { # resc-file [extra -e commands]
  local resc=$1; shift
  local ui=(--console --disable-gui)
  [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ] && [ -z "${RENODE_BOX_CONSOLE:-}" ] && ui=()
  echo "renode: $resc  (quit: type 'quit' in the monitor)"
  "$RENODE_DIR/renode" --config "$RENODE_CONFIG" "${ui[@]}" \
    -e "\$ex_dir=@$EX_DIR; \$ex_out=@$EX_OUT; \$demos=@${RENODE_BOX_DEMOS:-}" "$@" -e "include @$resc; start"
}

# Headless Robot Framework test: renode-test with EX_DIR/EX_OUT/DEMOS as robot variables.
ex_robot() { # robot-file [renode-test args]
  local robot=$1; shift
  case "$robot" in /*) ;; *) robot="$EX_DIR/$robot" ;; esac
  mkdir -p "$EX_OUT/robot"
  # run from the output dir: renode-test writes robot_output.xml/log.html/snapshots to the cwd
  (cd "$EX_OUT/robot" && "$RENODE_DIR/renode-test" --renode-config "$RENODE_CONFIG" -r "$EX_OUT/robot" \
    --variable "EX_DIR:$EX_DIR" --variable "EX_OUT:$EX_OUT" --variable "DEMOS:${RENODE_BOX_DEMOS:-}" \
    "$@" "$robot")
}

# Headless Renode in the background (for host-side clients: gdb, sockets). Sets EX_RENODE_PID;
# the caller stops it with ex_renode_stop. Output goes to the log file, never to a pipe.
ex_renode_bg() { # log-file monitor-commands
  local logf=$1 cmds=$2
  "$RENODE_DIR/renode" --config "$RENODE_CONFIG" --disable-gui --plain \
    -e "\$ex_dir=@$EX_DIR; \$ex_out=@$EX_OUT; \$demos=@${RENODE_BOX_DEMOS:-}" -e "$cmds" >"$logf" 2>&1 </dev/null &
  EX_RENODE_PID=$!
}
ex_renode_stop() { [ -n "${EX_RENODE_PID:-}" ] && kill "$EX_RENODE_PID" 2>/dev/null; wait "${EX_RENODE_PID:-}" 2>/dev/null; true; }
ex_free_port() { python -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1",0)); print(s.getsockname()[1])'; }
ex_wait_port() { # port [seconds]: until something listens on 127.0.0.1:port
  local i
  for ((i = 0; i < ${2:-60} * 4; i++)); do
    (exec 3<>"/dev/tcp/127.0.0.1/$1") 2>/dev/null && return 0
    sleep 0.25
  done
  echo "nothing listens on port $1" >&2; return 1
}

# Another Box ID's launcher (Rust, Zig toolchains): $BOX_<VAR>, else the sibling folder. Not
# copied or installed here; when the ID is missing the example exits 3 (= skipped) and says why.
ex_sibling_launcher() { # ID-folder ENV-VAR launcher-name
  local dir=${!2:-} l
  [ -n "$dir" ] || dir="$RENODE_BOX_ROOT/../$1"
  l="$dir/$3"
  if [ ! -x "$l" ]; then
    echo "skip: needs $1 ($3) for its toolchain: set $2 or put the ID next to 32_06_renode" >&2
    exit 3
  fi
  printf '%s' "$(cd "$dir" && pwd -P)/$3"
}
