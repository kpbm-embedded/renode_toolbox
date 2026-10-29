*** Settings ***
Documentation     @NAME@: line commands on UART0 and the LED of an nRF52840 board.
...               Run: ./renode-box robot <dir>/@NAME@/@NAME@.robot   (build first: ./renode-box run make -C <dir>/@NAME@)
Suite Setup       Setup
Suite Teardown    Teardown
Test Teardown     Test Teardown
Resource          ${RENODEKEYWORDS}

*** Variables ***
${ELF}            ${CURDIR}/build/@NAME@.elf
${UART}           sysbus.uart0

*** Keywords ***
Create Machine
    Execute Command           $elf=@${ELF}
    Execute Command           include @${CURDIR}/@NAME@.resc
    Create Terminal Tester    ${UART}    defaultPauseEmulation=True

*** Test Cases ***
Should Echo A Line
    Create Machine
    Wait For Prompt On Uart   >
    Write Line To Uart        hello
    Wait For Line On Uart     echo: hello

Should Toggle The LED On Command
    Create Machine
    Create LED Tester         sysbus.gpio0.led
    Wait For Prompt On Uart   >
    Write Line To Uart        led
    Wait For Line On Uart     led is on
    Assert LED State          true
    Write Line To Uart        led
    Wait For Line On Uart     led is off
    Assert LED State          false
