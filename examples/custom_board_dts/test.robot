*** Settings ***
Documentation     DTS -> dts2repl -> Renode platform -> firmware: WeAct STM32H743 core board.
Suite Setup       Setup
Suite Teardown    Teardown
Test Teardown     Test Teardown
Resource          ${RENODEKEYWORDS}

*** Keywords ***
Create Machine
    Execute Command           $ex_out=@${EX_OUT}
    Execute Command           include @${EX_DIR}/weact_h743.resc
    Create Terminal Tester    sysbus.usart1    defaultPauseEmulation=True

*** Test Cases ***
Should Have The Peripherals From The DTS
    Create Machine
    ${p}=                     Execute Command    peripherals
    Should Contain            ${p}    usart1
    Should Contain            ${p}    led0
    Should Contain            ${p}    gpioe

Should Run The Firmware On The Generated Platform
    Create Machine
    Create LED Tester         sysbus.gpioe.led0
    Wait For Line On Uart     Hello from WeAct STM32H743
    Wait For Line On Uart     led on
    Assert LED State          true
    Wait For Line On Uart     led off
    Assert LED State          false
    Wait For Line On Uart     done
