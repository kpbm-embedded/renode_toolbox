*** Settings ***
Documentation     A peripheral written in Python (PythonPeripheral in the .repl): firmware reads it, the test drives it.
Suite Setup       Setup
Suite Teardown    Teardown
Test Teardown     Test Teardown
Resource          ${RENODEKEYWORDS}

*** Keywords ***
Create Machine
    Execute Command           $ex_dir=@${EX_DIR}
    Execute Command           $ex_out=@${EX_OUT}
    Execute Command           include @${EX_DIR}/pysensor.resc
    Create Terminal Tester    sysbus.usart1    defaultPauseEmulation=True

*** Test Cases ***
Should Find The Python Sensor
    Create Machine
    Wait For Line On Uart     sensor id 0x5e450001
    Wait For Line On Uart     temp 21.50 C

Should Follow Temperature Changes
    Create Machine
    Wait For Line On Uart     temp 21.50 C
    Execute Command           sysbus WriteDoubleWord 0x40080010 3075
    Wait For Line On Uart     temp 30.75 C
    Execute Command           sysbus WriteDoubleWord 0x40080010 5
    Wait For Line On Uart     temp 0.05 C

Should Count Samples In The Peripheral
    Create Machine
    Wait For Line On Uart     temp 21.50 C
    Execute Command           emulation RunFor "0.05"
    ${n}=                     Execute Command    sysbus ReadDoubleWord 0x4008000C
    Should Be True            int("""${n}""".strip(), 16) > 10
