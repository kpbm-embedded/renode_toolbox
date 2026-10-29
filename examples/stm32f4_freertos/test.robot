*** Settings ***
Documentation     FreeRTOS V11 on BlackPill F411: scheduler, queue, software timer, LED timing.
Suite Setup       Setup
Suite Teardown    Teardown
Test Teardown     Test Teardown
Resource          ${RENODEKEYWORDS}

*** Keywords ***
Create Machine
    Execute Command           $ex_dir=@${EX_DIR}
    Execute Command           $ex_out=@${EX_OUT}
    Execute Command           include @${EX_DIR}/blackpill_f411.resc
    Create Terminal Tester    sysbus.usart1    defaultPauseEmulation=True
    Create LED Tester         sysbus.gpioPortC.led

*** Test Cases ***
Should Start The Scheduler
    Create Machine
    Wait For Line On Uart     FreeRTOS V11.* on BlackPill    treatAsRegex=true
    Wait For Line On Uart     rx 0
    Wait For Line On Uart     rx 5

Should Fire The Software Timer On Time
    Create Machine
    Wait For Line On Uart     timer 2 s, tick 2000

Should Blink Every 250 ms
    Create Machine
    Wait For Line On Uart     rx 1
    Assert LED Is Blinking    testDuration=2  onDuration=0.25  offDuration=0.25  tolerance=0.05  pauseEmulation=true
