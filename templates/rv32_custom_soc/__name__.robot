*** Settings ***
Documentation     @NAME@: the hand-written platform loads, the firmware boots, the LED follows.
...               Run: ./renode-box robot <dir>/@NAME@/@NAME@.robot   (build first: ./renode-box run make -C <dir>/@NAME@)
Suite Setup       Setup
Suite Teardown    Teardown
Test Teardown     Test Teardown
Resource          ${RENODEKEYWORDS}

*** Variables ***
${ELF}            ${CURDIR}/build/@NAME@.elf
${UART}           sysbus.usart1

*** Keywords ***
Create Machine
    Execute Command           $elf=@${ELF}
    Execute Command           include @${CURDIR}/@NAME@.resc
    Create Terminal Tester    ${UART}    defaultPauseEmulation=True

*** Test Cases ***
Should Boot
    Create Machine
    Wait For Line On Uart     @NAME@ up

Should Drive The LED
    Create Machine
    Create LED Tester         sysbus.gpioPortD.led    defaultTimeout=2
    Wait For Line On Uart     led on
    Assert LED State          true
    Wait For Line On Uart     led off
    Assert LED State          false
