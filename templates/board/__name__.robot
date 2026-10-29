*** Settings ***
Documentation     @NAME@: the firmware prints its banner on the console UART.
Suite Setup       Setup
Suite Teardown    Teardown
Test Teardown     Test Teardown
Resource          ${RENODEKEYWORDS}

*** Variables ***
${ELF}            ${CURDIR}/firmware.elf
${UART}           usart1
${BANNER}         Hello

*** Keywords ***
Create Machine
    Execute Command           $elf=@${ELF}
    Execute Command           include @${CURDIR}/@NAME@.resc
    Create Terminal Tester    sysbus.${UART}    defaultPauseEmulation=True

*** Test Cases ***
Should Print The Banner
    Create Machine
    Wait For Line On Uart     ${BANNER}    timeout=10
