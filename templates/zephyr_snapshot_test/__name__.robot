*** Settings ***
Documentation     @NAME@: boot once, save a snapshot, start every test from it (fast suites).
...               Run: ./renode-box robot <dir>/@NAME@/@NAME@.robot  [--variable ELF:<zephyr.elf>]
Suite Setup       Setup
Suite Teardown    Teardown
Test Teardown     Test Teardown
Resource          ${RENODEKEYWORDS}
Library           OperatingSystem

*** Variables ***
${ELF}            %{RENODE_BOX_DEMOS}/zephyr_shell_nrf52840.elf-s_1110556-9653ab7fffe1427c50fa6b837e55edab38925681
${PLATFORM}       ${CURDIR}/@NAME@.repl
${UART}           sysbus.uart0
${PROMPT}         uart:~$
${SNAPSHOT}       ${TEMPDIR}/@NAME@_booted.save

*** Keywords ***
Create Snapshot
    [Documentation]           Boot to the shell prompt once and save the whole emulation.
    Execute Command           mach create "@NAME@"
    Execute Command           machine LoadPlatformDescription @${PLATFORM}
    Execute Command           sysbus LoadELF @${ELF}
    Create Terminal Tester    ${UART}    defaultPauseEmulation=True
    Wait For Prompt On Uart   ${PROMPT}
    Execute Command           Save @${SNAPSHOT}

Start From Snapshot
    Execute Command           Load @${SNAPSHOT}
    Execute Command           mach set 0
    Create Terminal Tester    ${UART}    defaultPauseEmulation=True

*** Test Cases ***
Snapshot Should Be Written
    Create Snapshot
    File Should Exist         ${SNAPSHOT}

Ping Should Answer From The Snapshot
    Start From Snapshot
    Write Line To Uart        demo ping
    Wait For Line On Uart     pong

Kernel Command Should Work From The Snapshot
    Start From Snapshot
    Write Line To Uart        kernel version
    Wait For Line On Uart     Zephyr version

Snapshot Should Not Boot Again
    Start From Snapshot
    Write Line To Uart        demo ping
    Wait For Line On Uart     pong
    Should Not Be On Uart     Booting Zephyr    timeout=0.5
