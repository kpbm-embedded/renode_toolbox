*** Settings ***
Documentation     32_03's ztest-basic (riscv32_virtual, built -O0) in Renode with a binary PC trace; the suite
...               must pass. example.sh turns the trace into line coverage.
Suite Setup       Setup
Suite Teardown    Teardown
Test Teardown     Test Teardown
Resource          ${RENODEKEYWORDS}

*** Variables ***
${ELF}            ${EX_OUT}/zephyr/examples/ztest-basic/riscv32_virtual/zephyr/zephyr.elf
${BOARD_RESC}     ${EMPTY}
${TRACE}          ${EX_OUT}/ztest.bin.gz

*** Test Cases ***
Ztest Suite Passes With Tracing
    Execute Command           $elf=@${ELF}
    Execute Command           include @${BOARD_RESC}
    Execute Command           cpu CreateExecutionTracing "tracer" @${TRACE} PC true true
    Create Terminal Tester    sysbus.uart0    defaultPauseEmulation=True    timeout=60
    Wait For Line On Uart     Running TESTSUITE fifo
    Wait For Line On Uart     SUITE PASS - 100.00% [fifo]
    Wait For Line On Uart     PROJECT EXECUTION SUCCESSFUL
