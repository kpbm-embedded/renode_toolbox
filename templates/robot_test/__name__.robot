*** Settings ***
Documentation     @NAME@: Renode test skeleton. Run: ./renode-box robot @NAME@.robot --variable RESC:<board.resc> --variable ELF:<fw.elf>
Suite Setup       Setup
Suite Teardown    Teardown
Test Teardown     Test Teardown
Resource          ${RENODEKEYWORDS}

*** Variables ***
${RESC}           ${CURDIR}/board.resc
${ELF}            ${EMPTY}
${UART}           sysbus.usart1
${LED}            sysbus.gpioPortC.led
${BUTTON}         sysbus.gpioPortA.button

*** Keywords ***
Create Machine
    IF    "${ELF}" != ""
        Execute Command       $elf=@${ELF}
    END
    Execute Command           include @${RESC}
    Create Terminal Tester    ${UART}    defaultPauseEmulation=True

*** Test Cases ***
Should Talk Over The UART
    [Tags]                    uart
    Create Machine
    Wait For Line On Uart     .+    treatAsRegex=true    timeout=10
    # Write Line To Uart      help
    # Wait For Prompt On Uart  uart:~$

Should Drive LED And Button
    [Tags]                    gpio    skipped
    Create Machine
    Create LED Tester         ${LED}
    Execute Command           ${BUTTON} Press
    Assert LED State          true    timeout=1
    Execute Command           ${BUTTON} Release
    # Assert LED Is Blinking  testDuration=2  onDuration=0.5  offDuration=0.5  tolerance=0.1

Should Keep Virtual Time
    [Tags]                    time
    Create Machine
    Execute Command           emulation RunFor "0.5"
    ${t}=                     Execute Command    emulation GetTimeSourceInfo
    Should Contain            ${t}    Elapsed Virtual Time: 00:00:00.5

Should Log In To Linux
    [Tags]                    linux    skipped
    Create Machine
    Wait For Prompt On Uart   login:    timeout=120
    Write Line To Uart        root
    Wait For Prompt On Uart   \#${SPACE}
    Write Line To Uart        uname -a
    Wait For Line On Uart     Linux
