#!/usr/bin/env bash
# about: west-renode-gen in a throwaway Zephyr workspace: Renode files for the BlackPill F411, then twister runs 32_03's ztest-basic in Renode with --coverage-tool renode
# Usage (via ./renode-box examples): build | run | test. Needs 32_03_zephyr ($BOX_ZEPHYR or the sibling) and the
# optional add-on (./renode-box extras install west-renode-gen); exits 3 (skip) without them.
# 32_03 is never changed: build makes EX_OUT/ws with a shared git clone of its zephyr tree (objects borrowed, files
# checked out here), symlinks to its modules, west-renode-gen added to that copy's manifest, and its patches applied
# to that copy only. Toolchain and west come from 32_03's env.sh; dts2repl and renode-retracer from this ID.
# shellcheck source-path=SCRIPTDIR source=../fw/ex.sh
. "$(dirname "$0")/../fw/ex.sh"
BOARD=blackpill_f411ce
zephyr_id() {
  local d
  for d in "${BOX_ZEPHYR:-}" "${BOX_ZEPHYR:-}/../.." "$RENODE_BOX_ROOT/../32_03_zephyr"; do
    [ -n "$d" ] && [ -x "$d/scripts/app" ] && { (cd "$d" && pwd -P); return 0; }
  done
  echo "skip: needs 32_03_zephyr (scripts/app): set BOX_ZEPHYR or put the ID next to 32_06_renode" >&2; exit 3
}
ZID=$(zephyr_id)
GEN=$RENODE_BOX_ROOT/install/west-renode-gen
if [ ! -r "$GEN/west/west-renode-gen.py" ]; then   # build: no-op (so `install` does not fail); test/run: skip
  echo "skip: optional add-on missing: ./renode-box extras install west-renode-gen" >&2
  [ "${1:-run}" = build ] && exit 0
  exit 3
fi
ZBASE=$("$ZID/scripts/app" where | awk '$1=="zephyr_base" {print $2}')
ZWS=$(dirname "$ZBASE")
WS=$EX_OUT/ws
PYENV=$(command -v python)   # this ID's env python (pyelftools 0.30 for the retracer)

workspace() { # fresh throwaway copy of 32_03's workspace at the same zephyr commit
  local rev; rev=$(git -C "$ZBASE" rev-parse HEAD)
  if [ -d "$WS/zephyr/.git" ]; then
    git -C "$WS/zephyr" checkout -q -f "$rev" && git -C "$WS/zephyr" clean -fdq
  else
    mkdir -p "$WS"
    git clone -q --shared --no-checkout "$ZBASE" "$WS/zephyr" && git -C "$WS/zephyr" checkout -q "$rev"
  fi
  local d; for d in modules bootloader tools; do [ -e "$ZWS/$d" ] && ln -sfn "$ZWS/$d" "$WS/$d"; done
  ln -sfn "$GEN" "$WS/renode-gen"
  mkdir -p "$WS/.west" && printf '[manifest]\npath = zephyr\nfile = west.yml\n\n[zephyr]\nbase = zephyr\n' >"$WS/.west/config"
  # add the module to this copy's manifest (32_03's venv has PyYAML)
  zenv python - "$WS/zephyr/west.yml" <<'PY'
import sys, yaml
p = sys.argv[1]; m = yaml.safe_load(open(p))
m["manifest"]["projects"].append({"name": "west-renode-gen", "url": "https://github.com/antmicro/west-renode-gen",
    "revision": "a7ac65081e3516bc1c8e6f1727c6f4a88265d88a", "path": "renode-gen", "west-commands": "west/west-commands.yml"})
yaml.safe_dump(m, open(p, "w"), sort_keys=False)
PY
  # helpers: dts2repl (this ID's env) for renode-gen; renode-retracer for twister's renode coverage backend
  mkdir -p "$EX_OUT/pylib" "$EX_OUT/bin"
  ln -sfn "$(python -c 'import dts2repl, os; print(os.path.dirname(dts2repl.__file__))')" "$EX_OUT/pylib/dts2repl"
  printf '#!/bin/sh\nexec "%s" "%s" "$@"\n' "$PYENV" "$RENODE_DIR/tools/execution_tracer/execution_tracer_reader.py" >"$EX_OUT/bin/renode-retracer"
  chmod +x "$EX_OUT/bin/renode-retracer"
}
zenv() { # run a command with 32_03's toolchain env, pointed at the throwaway workspace
  (
    # shellcheck disable=SC1091
    . "$ZID/toolchain/zephyr/env.sh" >/dev/null
    export ZEPHYR_BASE="$WS/zephyr" PYTHONPATH="$EX_OUT/pylib${PYTHONPATH:+:$PYTHONPATH}" PATH="$EX_OUT/bin:$PATH"
    cd "$WS" && "$@"
  )
}
build() {
  workspace
  # patch 0001 (Renode execution-trace Kconfig + run_renode overlay) applies to Zephyr v4.4.2; 0002 (twister
  # --coverage-tool renode) does not (conflicts in twisterlib/coverage.py): its job, trace -> .info -> merge,
  # is done below with lib/covflow.py instead
  git -C "$WS/zephyr" apply "$GEN/zephyr/patches/0001-add-renode-execution-trace-backend.patch"
  zenv west renode-gen -b "$BOARD" -c -o
}
check() {
  local out=$EX_OUT/twister infos=() t
  # twister runs every case of 32_03's ztest-basic on the BlackPill F411 in Renode (handler from the generated
  # board files), each build with the Renode trace on and no optimisation
  zenv west twister -p "$BOARD" --force-platform -T "$ZID/examples/zephyr/ztest-basic" --outdir "$out" --clobber-output \
    -j "${BOXT_JOBS:-4}" --inline-logs -x=CONFIG_COVERAGE=y -x=CONFIG_COVERAGE_RENODE_EXECUTION_TRACE=y \
    -x=CONFIG_NO_OPTIMIZATIONS=y
  python - "$out/twister.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
st = {t["name"]: (t["status"], t.get("platform")) for t in d["testsuites"]}
print("twister:", st)
sys.exit(0 if st and all(s == "passed" for s, _ in st.values()) else 1)
PY
  while IFS= read -r t; do
    local n; n=$(basename "$(dirname "$(dirname "$t")")")
    python "$RENODE_BOX_ROOT/lib/covflow.py" info --elf "$(dirname "$t")/zephyr.elf" --name "$n" -o "$EX_OUT/$n.info" "$t" >/dev/null
    infos+=("$EX_OUT/$n.info")
  done < <(find "$out" -name zephyr_trace.bin.gz | sort)
  [ ${#infos[@]} -ge 2 ] || { echo "FAIL: expected a trace per twister scenario, got ${#infos[@]}"; return 1; }
  python "$RENODE_BOX_ROOT/lib/covflow.py" merge -o "$EX_OUT/merged.info" "${infos[@]}"
  python "$RENODE_BOX_ROOT/lib/covflow.py" summary "$EX_OUT/merged.info" --only ztest-basic/src/ --min 'src/fifo.c:100'
}
case "${1:-run}" in
  build) build ;;
  run)   build; zenv west build -p auto -b "$BOARD" -d "$EX_OUT/hello" "$WS/zephyr/samples/hello_world" && zenv west build -d "$EX_OUT/hello" -t run ;;
  test)  build; check ;;
  *) echo "usage: example.sh build|run|test" >&2; exit 2 ;;
esac
