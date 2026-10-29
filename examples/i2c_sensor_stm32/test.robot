*** Settings ***
Documentation     A Renode sensor model on an I2C bus: register-level driver, values set from the test, NACK path.
Suite Setup       Setup
Suite Teardown    Teardown
Test Teardown     Test Teardown
Resource          ${RENODEKEYWORDS}

*** Keywords ***
Create Machine
    Execute Command           $ex_dir=@${EX_DIR}
    Execute Command           $ex_out=@${EX_OUT}
    Execute Command           include @${EX_DIR}/i2c.resc
    Create Terminal Tester    sysbus.usart1    defaultPauseEmulation=True

*** Test Cases ***
Should Report A Missing Device
    Create Machine
    Wait For Line On Uart     no device at 0x48 (NACK)

Should Read The Sensor
    Create Machine
    Wait For Line On Uart     tmp103 24 C

Should Follow The Sensor Value
    Create Machine
    Wait For Line On Uart     tmp103 24 C
    Execute Command           sysbus.i2c1.tmp103 Temperature 37
    Wait For Line On Uart     tmp103 37 C
    Execute Command           sysbus.i2c1.tmp103 Temperature -12
    Wait For Line On Uart     tmp103 -12 C
