*** Settings ***
Documentation     Prebuilt Linux images on Renode, fully offline (cached by ./renode-box install).
Suite Setup       Setup
Suite Teardown    Teardown
Test Teardown     Test Teardown
Resource          ${RENODEKEYWORDS}

*** Keywords ***
Boot
    [Arguments]               ${resc}    ${uart}
    Execute Command           $demos=@${DEMOS}
    Execute Command           include @${EX_DIR}/${resc}
    Create Terminal Tester    ${uart}    defaultPauseEmulation=True

*** Test Cases ***
Should Boot Linux On The K210
    Boot                      k210_linux.resc    sysbus.uart
    Wait For Line On Uart     Linux version    timeout=60
    Wait For Prompt On Uart   / \#    timeout=120
    Write Line To Uart        uname -m
    Wait For Line On Uart     riscv64

Should Boot Linux On Zynq And Log In
    Boot                      zynq_linux.resc    sysbus.uart0
    Wait For Line On Uart     Booting Linux on physical CPU 0x0
    Wait For Prompt On Uart   buildroot login:    timeout=60
    Write Line To Uart        root
    Wait For Prompt On Uart   \#${SPACE}
    Write Line To Uart        uname -m
    Wait For Line On Uart     armv7l
