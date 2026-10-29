*** Settings ***
Documentation     @NAME@: FreeRTOS scheduler, queue, mutex and task timing on the BlackPill F411 model.
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
Should Start The Scheduler
    Create Machine
    Wait For Line On Uart     @NAME@: FreeRTOS V11

Should Pass Samples Through The Queue
    Create Machine
    Wait For Line On Uart     sample 7 blinks
    Wait For Line On Uart     sample 21 blinks

Should Keep Task Timing
    Create Machine
    # 5th sample after 4 x 200 ms; the tick counter runs at 1 kHz on virtual time
    ${l}=                     Wait For Line On Uart    sample 35 blinks (\\d+) tick (\\d+)    treatAsRegex=true
    Should Be True            790 <= int(${l.Groups[1]}) <= 810

Should Blink Every 500 ms
    Create Machine
    Create LED Tester         sysbus.gpioPortC.led
    Wait For Line On Uart     sample 7
    Assert LED Is Blinking    testDuration=3    onDuration=0.5    offDuration=0.5    tolerance=0.05
