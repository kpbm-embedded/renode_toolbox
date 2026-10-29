*** Settings ***
Documentation     A platform written from scratch (.repl): RV32EC core, memories, USART and GPIO models reused.
Suite Setup       Setup
Suite Teardown    Teardown
Test Teardown     Test Teardown
Resource          ${RENODEKEYWORDS}

*** Keywords ***
Create Machine
    Execute Command           $ex_dir=@${EX_DIR}
    Execute Command           $ex_out=@${EX_OUT}
    Execute Command           include @${EX_DIR}/ch32v003.resc
    Create Terminal Tester    sysbus.usart1    defaultPauseEmulation=True

*** Test Cases ***
Should Boot On The RV32EC Core
    Create Machine
    Wait For Line On Uart     CH32V003-like RV32EC up
    Wait For Line On Uart     data/bss ok
    Wait For Line On Uart     (E)

Should Blink The LED On PD0
    Create Machine
    Create LED Tester         sysbus.gpioPortD.led    defaultTimeout=2
    Wait For Line On Uart     led on
    Assert LED State          true
    Wait For Line On Uart     led off
    Assert LED State          false

Should Map Memory Like The Chip
    Create Machine
    ${p}=                     Execute Command    peripherals
    Should Contain            ${p}    0x20000000
    Should Contain            ${p}    0x40013800
