*** Settings ***
Documentation     nRF52840 nice!nano: own bare-metal firmware and the prebuilt Zephyr shell sample (offline copy).
Suite Setup       Setup
Suite Teardown    Teardown
Test Teardown     Test Teardown
Resource          ${RENODEKEYWORDS}

*** Variables ***
${ZEPHYR_SHELL}   zephyr_shell_nrf52840.elf-s_1110556-9653ab7fffe1427c50fa6b837e55edab38925681

*** Keywords ***
Create Machine
    [Arguments]               ${elf}
    Execute Command           $ex_dir=@${EX_DIR}
    Execute Command           $ex_out=@${EX_OUT}
    Execute Command           $elf=@${elf}
    Execute Command           include @${EX_DIR}/nicenano.resc
    Create Terminal Tester    sysbus.uart0    defaultPauseEmulation=True

*** Test Cases ***
Should Echo On The Bare-Metal UART
    Create Machine            ${EX_OUT}/nicenano_hello.elf
    Wait For Line On Uart     Hello from nRF52840 nice!nano
    Wait For Prompt On Uart   >
    Write Line To Uart        renode    waitForEcho=true
    Wait For Line On Uart     led toggles so far:

Should Toggle The LED
    Create Machine            ${EX_OUT}/nicenano_hello.elf
    Create LED Tester         sysbus.gpio0.led
    Assert LED State          true    timeout=1
    Assert LED State          false   timeout=1

Should Run The Prebuilt Zephyr Shell
    Create Machine            ${DEMOS}/${ZEPHYR_SHELL}
    Wait For Prompt On Uart   uart:~$
    Write Line To Uart        demo ping
    Wait For Line On Uart     pong
