*** Settings ***
Documentation     @NAME@: Zig firmware (Zig of 32_24_microzig) on the nRF52840 model; logic.zig is unit-tested by make.
...               Run: ./renode-box robot <dir>/@NAME@/@NAME@.robot   (build first: ./renode-box run make -C <dir>/@NAME@)
Suite Setup       Setup
Suite Teardown    Teardown
Test Teardown     Test Teardown
Resource          ${RENODEKEYWORDS}

*** Keywords ***
Create Machine
    Execute Command           include @${CURDIR}/@NAME@.resc
    Create Terminal Tester    sysbus.uart0    defaultPauseEmulation=True

*** Test Cases ***
Should Boot With Its Data Section
    Create Machine
    Wait For Line On Uart     Hello from Zig on nRF52840
    Wait For Line On Uart     data ok

Should Compute CRC-8 Like The Host Test
    Create Machine
    Wait For Prompt On Uart   >
    Write Line To Uart        crc 123456789
    # 0xF4, the value logic.zig's host test checks
    Wait For Line On Uart     crc8 244

Should Toggle The LED
    Create Machine
    Create LED Tester         sysbus.gpio0.led
    Wait For Prompt On Uart   >
    Write Line To Uart        led
    Wait For Line On Uart     led on
    Assert LED State          true
    Write Line To Uart        bogus
    Wait For Line On Uart     unknown command
