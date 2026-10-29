*** Settings ***
Documentation     Interrupt-driven firmware: timer IRQ timing (virtual time, LED blink check) and GPIO edge IRQs.
Suite Setup       Setup
Suite Teardown    Teardown
Test Teardown     Test Teardown
Resource          ${RENODEKEYWORDS}

*** Keywords ***
Create Machine
    Execute Command           $ex_dir=@${EX_DIR}
    Execute Command           $ex_out=@${EX_OUT}
    Execute Command           include @${EX_DIR}/nrf_irq.resc
    Create Terminal Tester    sysbus.uart0    defaultPauseEmulation=True

*** Test Cases ***
Timer IRQ Should Run On Virtual Time
    Create Machine
    Wait For Line On Uart     nrf52840 irq demo
    Execute Command           emulation RunFor "1.1"
    Wait For Line On Uart     ticks 4    timeout=0
    ${t}=                     Execute Command    sysbus ReadDoubleWord `sysbus GetSymbolAddress "ticks"`
    Should Be Equal As Integers    ${t.strip()}    4

LED Should Blink At 2 Hz
    Create Machine
    Create LED Tester         sysbus.gpio0.led
    Wait For Line On Uart     nrf52840 irq demo
    Assert LED Is Blinking    testDuration=2    onDuration=0.25    offDuration=0.25    tolerance=0.05

Button Edges Should Raise GPIOTE IRQs
    Create Machine
    Wait For Line On Uart     nrf52840 irq demo
    Execute Command           sysbus.gpio0.button PressAndRelease
    Wait For Line On Uart     button presses 1
    Execute Command           sysbus.gpio0.button PressAndRelease
    Wait For Line On Uart     button presses 2
