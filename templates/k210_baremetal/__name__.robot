*** Settings ***
Documentation     @NAME@: banner and loop on the K210 UARTHS.
...               Run: ./renode-box robot <dir>/@NAME@/@NAME@.robot   (build first: ./renode-box run make -C <dir>/@NAME@)
Suite Setup       Setup
Suite Teardown    Teardown
Test Teardown     Test Teardown
Resource          ${RENODEKEYWORDS}

*** Variables ***
${ELF}            ${CURDIR}/build/@NAME@.elf
${UART}           sysbus.uart

*** Keywords ***
Create Machine
    Execute Command           $elf=@${ELF}
    Execute Command           include @${CURDIR}/@NAME@.resc
    Create Terminal Tester    ${UART}    defaultPauseEmulation=True

*** Test Cases ***
Should Boot On Hart 0 In RV64
    Create Machine
    Wait For Line On Uart     @NAME@ on K210, hart 0, rv64

Should Keep Running
    Create Machine
    Wait For Line On Uart     loop 3
