#!/usr/bin/env bash
# Every renode-box command in --dry-run mode (no downloads, builds, moves or launches),
# read-only commands for real, plus shellcheck. Usage: tests/test_dry_run.sh
set -uo pipefail
HERE=$(cd "$(dirname "$0")/.." && pwd -P)
R="$HERE/renode-box"
pass=0; failn=0

check() { # name expected-regex cmd...
  local name=$1 re=$2; shift 2
  local out rc
  out=$(timeout 300 "$@" 2>&1); rc=$?
  if [ "$rc" -eq 0 ] && grep -qE -- "$re" <<<"$out"; then
    printf 'ok    %s\n' "$name"; pass=$((pass+1))
  else
    printf 'FAIL  %s (rc=%s)\n%s\n' "$name" "$rc" "$(tail -5 <<<"$out" | sed 's/^/      /')"; failn=$((failn+1))
  fi
}

check help            'usage: ./renode-box'                      "$R" help
check where           '^renode +/'                               "$R" where
check status          'renode +1\.17'                            "$R" status
check bootstrap       'bootstrap|\+ timeout .*pixi.* install'    "$R" --dry-run bootstrap
check install         'examples build: stm32f4_blackpill'        "$R" --dry-run install
check update          'pinned vs newest|\+ curl https://api.github.com/repos/renode/renode' "$R" --dry-run update
check update-env      '\+ timeout .*pixi.* update'               "$R" --dry-run update --env
check clean           'nothing to clean|dry run: re-run with --yes' "$R" clean
check clean-all       'dry run: re-run with --yes'               "$R" clean --all
check doctor          'doctor: [0-9]+ ok'                        bash -c "'$R' doctor || true"
check shell           '\+ true'                                  "$R" --dry-run shell -- true
check run             '\+ renode-test --help'                    "$R" --dry-run run renode-test --help
check renode          '\+ renode --version'                      "$R" --dry-run renode --version
check robot           '\+ renode-test x.robot'                   "$R" --dry-run robot x.robot
check repl            '\+ dts2repl x.dts'                        "$R" --dry-run repl x.dts
check platforms       'cpus/stm32f412.repl'                      "$R" platforms stm32f4
check test            '\+ bash .*tests/test_smoke.sh'            "$R" --dry-run test
check new-board       '\+ copy .*templates/board'                "$R" --dry-run new board myboard --dir /nonexistent
check new-robot       '\+ copy .*templates/robot_test'           "$R" --dry-run new robot_test mytest --dir /nonexistent
check new-fw          '\+ copy .*templates/stm32f4_baremetal'     "$R" --dry-run new stm32f4_baremetal myfw --dir /nonexistent
check examples-new    'uart_hub_two_nodes'                       "$R" examples list
check examples-list   'stm32f4_freertos'                         "$R" examples list
check examples-build  'example.sh build'                         "$R" --dry-run examples build
check examples-test   'example.sh test'                          "$R" --dry-run examples test nrf52840_nicenano
check examples-run    'example.sh run'                           "$R" --dry-run examples run riscv_k210_litex
check native          'renode install/renode/renode'             "$R" --dry-run native
check native-print    'renode-test @robot'                       "$R" native --print
check relocate        'pixi env already matches|re-creating'     "$R" --dry-run relocate
check pack            '\+ tar .*-cf .*renode-box_'               "$R" --dry-run pack

# lint: launcher, libs, tests, examples (incl. the shared helper) with shellcheck
if command -v shellcheck >/dev/null 2>&1; then
  mapfile -t files < <(cd "$HERE" && printf '%s\n' renode-box lib/*.bash tests/*.sh examples/*/example.sh examples/fw/ex.sh)
  if out=$(cd "$HERE" && shellcheck -x -P SCRIPTDIR "${files[@]}" 2>&1); then
    printf 'ok    shellcheck (%s files)\n' "${#files[@]}"; pass=$((pass+1))
  else
    printf 'FAIL  shellcheck\n%s\n' "$(head -30 <<<"$out")"; failn=$((failn+1))
  fi
else
  echo "skip  shellcheck (not installed)"
fi

echo "dry-run: $pass ok, $failn failed"
[ "$failn" -eq 0 ]
