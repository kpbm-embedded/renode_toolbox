*** Settings ***
Documentation     @NAME@: banner, LED and KEY on the BlackPill F411 model.
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
Should Print The Banner
    Create Machine
    Wait For Line On Uart     @NAME@ on BlackPill F411

Should Blink The LED
    Create Machine
    Create LED Tester         sysbus.gpioPortC.led    defaultTimeout=2
    Wait For Line On Uart     led on
    Assert LED State          true
    Wait For Line On Uart     led off
    Assert LED State          false

Should See The KEY
    Create Machine
    Wait For Line On Uart     led on
    Execute Command           sysbus.gpioPortA.key Press
    Wait For Line On Uart     key pressed
