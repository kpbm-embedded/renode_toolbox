#!/usr/bin/env bash
# about: Zephyr dashboard artifacts (prebuilt ELF + dts2repl .repl): BlackPill F411, WeAct G431, STM32H7 reference board, Pico, i.MX 8M Plus M7 on 1.17.0; ESP32-S3 on the pinned nightly
# Usage (via ./renode-box examples): build | run [board] | test. build downloads the files listed in artifacts.tsv
# (sha256-checked, cached in cache/downloads/zephyr-dashboard, offline afterwards). The dashboard builds them with a
# Renode nightly; this example checks that the pinned 1.17.0 runs them. Dashboard files are dated: if they disappear
# upstream, the cached copies keep working; pick a newer set from https://zephyr-dashboard.renode.io.
# shellcheck source-path=SCRIPTDIR source=../fw/ex.sh
. "$(dirname "$0")/../fw/ex.sh"
BASE=https://zephyr-dashboard.renode.io
CACHE=$RENODE_BOX_ROOT/cache/downloads/zephyr-dashboard
fetch() {
  local zv rv b s ext want f url got
  zv=$(sed -n 's/^#\tzephyr=\(.*\)/\1/p' "$EX_DIR/artifacts.tsv"); rv=$(sed -n 's/^#\trenode=\(.*\)/\1/p' "$EX_DIR/artifacts.tsv")
  while IFS=$'\t' read -r b s ext want; do
    case "$b" in ''|'#'*) continue ;; esac
    f=$CACHE/$b/$s.$ext
    if [ ! -f "$f" ] || [ "$(sha256sum "$f" | cut -d' ' -f1)" != "$want" ]; then
      if [ "$ext" = elf ]; then url=$BASE/zephyr/$zv/$b/$s/$s.elf; else url=$BASE/zephyr_sim/$zv/$rv/$b/$s/$s.$ext; fi
      mkdir -p "$(dirname "$f")"
      curl -fsSL --retry 3 --connect-timeout 30 --max-time 600 -o "$f.part" "$url" || { echo "FAIL: download $url" >&2; return 1; }
      got=$(sha256sum "$f.part" | cut -d' ' -f1)
      [ "$got" = "$want" ] || { echo "FAIL: sha256 mismatch for $url ($got)" >&2; return 1; }
      mv "$f.part" "$f"
    fi
    mkdir -p "$EX_OUT/$b"
    if [ "$ext" = resc ]; then   # local copy: no log file, asciinema or 60 MB profiler output next to the cache
      grep -vE '^logFile |RecordToAsciinema|EnableProfilerCollapsedStack' "$f" >"$EX_OUT/$b/$s.resc"
    else cp -f "$f" "$EX_OUT/$b/$s.$ext"; fi
  done <"$EX_DIR/artifacts.tsv"
  echo "dashboard artifacts ready in $EX_OUT"
}
case "${1:-run}" in
  build) fetch ;;
  run)   fetch >/dev/null; b=${2:-blackpill_f411ce}; s=$(awk -F'\t' -v b="$b" '$1==b {print $2; exit}' "$EX_DIR/artifacts.tsv")
         [ -n "$s" ] || { echo "boards: $(awk -F'\t' '!/^#/ {print $1}' "$EX_DIR/artifacts.tsv" | sort -u | tr '\n' ' ')" >&2; exit 2; }
         ex_renode "$EX_OUT/$b/$s.resc" -e "\$bin=@$EX_OUT/$b/$s.elf" ;;
  test)  fetch; ex_robot test.robot
         n=$RENODE_BOX_ROOT/install/renode-nightly
         if [ -x "$n/renode-test" ]; then   # ESP32-S3: its USB serial model came after 1.17.0
           (cd "$EX_OUT/robot" && "$n/renode-test" --renode-config "$RENODE_CONFIG.nightly" -r "$EX_OUT/robot/nightly" \
              --variable "EX_OUT:$EX_OUT" "$EX_DIR/test_nightly.robot")
         else echo "note: ESP32-S3 case skipped: needs the dated nightly (./renode-box extras install renode-nightly)"; fi ;;
  *) echo "usage: example.sh build|run [board]|test" >&2; exit 2 ;;
esac
