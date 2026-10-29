*** Settings ***
Documentation     BlackPill F411 bare-metal: UART banner, LED blinking, KEY button.
Suite Setup       Setup
Suite Teardown    Teardown
Test Teardown     Test Teardown
Resource          ${RENODEKEYWORDS}

*** Variables ***
${UART}           sysbus.usart1

*** Keywords ***
Create Machine
    Execute Command           $ex_dir=@${EX_DIR}
    Execute Command           $ex_out=@${EX_OUT}
    Execute Command           include @${EX_DIR}/blackpill_f411.resc
    Create Terminal Tester    ${UART}    defaultPauseEmulation=True
    Create LED Tester         sysbus.gpioPortC.led    defaultTimeout=2

*** Test Cases ***
Should Print Banner
    Create Machine
    Wait For Line On Uart     Hello from BlackPill F411

Should Blink The LED
    Create Machine
    Wait For Line On Uart     blink 3 led=on
    Assert LED State          true
    Wait For Line On Uart     blink 4 led=off
    Assert LED State          false

Should See The KEY Button
    Create Machine
    Wait For Line On Uart     blink 1
    Execute Command           sysbus.gpioPortA.button Press
    Wait For Line On Uart     KEY pressed
    Execute Command           sysbus.gpioPortA.button Release
