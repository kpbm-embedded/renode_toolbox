*** Settings ***
Documentation     A peripheral written in C# and compiled by Renode at run time; firmware and monitor both use it.
Suite Setup       Setup
Suite Teardown    Teardown
Test Teardown     Test Teardown
Resource          ${RENODEKEYWORDS}

*** Keywords ***
Create Machine
    Execute Command           $ex_dir=@${EX_DIR}
    Execute Command           $ex_out=@${EX_OUT}
    Execute Command           include @${EX_DIR}/crc.resc
    Create Terminal Tester    sysbus.usart1    defaultPauseEmulation=True

*** Test Cases ***
Firmware Should Match The Accelerator
    Create Machine
    Wait For Line On Uart     crc sw 0x9ae0daaf hw 0x9ae0daaf bytes 8 MATCH

Monitor Should Drive The Peripheral Directly
    Create Machine
    Wait For Line On Uart     check done
    # the same 8 bytes ("12345678") written from the monitor, as a test bench would
    Execute Command           sysbus WriteDoubleWord 0x40081008 1
    Execute Command           sysbus WriteDoubleWord 0x40081000 0x34333231
    Execute Command           sysbus WriteDoubleWord 0x40081000 0x38373635
    ${crc}=                   Execute Command    sysbus ReadDoubleWord 0x40081004
    Should Be Equal As Integers    ${crc.strip()}    0x9AE0DAAF
