*** Settings ***
Documentation     @NAME@: function coverage of a firmware run: PC trace from Renode, functions from the ELF.
...               Run: ./renode-box robot <dir>/@NAME@/@NAME@.robot  [--variable ELF:<fw.elf>]
Suite Setup       Setup
Suite Teardown    Teardown
Test Teardown     Test Teardown
Resource          ${RENODEKEYWORDS}
Library           Process
Library           OperatingSystem

*** Variables ***
${ELF}            %{RENODE_BOX_DEMOS}/zephyr_shell_nrf52840.elf-s_1110556-9653ab7fffe1427c50fa6b837e55edab38925681
${PLATFORM}       ${CURDIR}/@NAME@.repl
${UART}           sysbus.uart0
${TRACE}          ${TEMPDIR}/@NAME@_trace.txt
${EXPECT_HIT}     main,shell_thread
${EXPECT_MISS}    ${EMPTY}

*** Keywords ***
Create Machine
    Execute Command           mach create "@NAME@"
    Execute Command           machine LoadPlatformDescription @${PLATFORM}
    Execute Command           sysbus LoadELF @${ELF}
    Remove File               ${TRACE}
    Execute Command           cpu CreateExecutionTracing "tracer" @${TRACE} PC
    Create Terminal Tester    ${UART}    defaultPauseEmulation=True

Coverage Should Pass
    [Documentation]           Stop the tracer (flushes the file) and run coverage.py on it.
    Execute Command           tracer Dispose
    ${r}=                     Run Process    python    ${CURDIR}/coverage.py    ${ELF}    ${TRACE}
    ...                       --expect-hit    ${EXPECT_HIT}    --expect-miss    ${EXPECT_MISS}    timeout=300s
    Log                       ${r.stdout}
    Should Be Equal As Integers    ${r.rc}    0    ${r.stdout}${r.stderr}
    Should Contain            ${r.stdout}    coverage:

*** Test Cases ***
Shell Commands Should Cover Their Handlers
    Create Machine
    Wait For Prompt On Uart   uart:~$
    Write Line To Uart        demo ping
    Wait For Line On Uart     pong
    Coverage Should Pass
