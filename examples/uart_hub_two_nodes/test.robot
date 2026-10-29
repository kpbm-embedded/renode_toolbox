*** Settings ***
Documentation     Two machines in one emulation: ping/pong over a UART hub, one tester per machine.
Suite Setup       Setup
Suite Teardown    Teardown
Test Teardown     Test Teardown
Resource          ${RENODEKEYWORDS}

*** Keywords ***
Create Nodes
    Execute Command           $ex_dir=@${EX_DIR}
    Execute Command           $ex_out=@${EX_OUT}
    Execute Command           include @${EX_DIR}/two_nodes.resc
    ${ping}=                  Create Terminal Tester    sysbus.usart1    machine=ping    defaultPauseEmulation=True
    ${pong}=                  Create Terminal Tester    sysbus.usart1    machine=pong    defaultPauseEmulation=True
    Set Test Variable         ${ping}
    Set Test Variable         ${pong}

*** Test Cases ***
Both Nodes Should Boot
    Create Nodes
    Wait For Line On Uart     node ping up    testerId=${ping}
    Wait For Line On Uart     node pong up    testerId=${pong}

Ping Should Get Pong Over The Hub
    Create Nodes
    Wait For Line On Uart     rx: ping 1    testerId=${pong}
    Wait For Line On Uart     got: pong 1    testerId=${ping}
    Wait For Line On Uart     got: pong 3    testerId=${ping}

Ping Should Time Out When The Hub Is Disconnected
    Create Nodes
    Execute Command           mach set "pong"
    Execute Command           connector Disconnect sysbus.usart2 link
    Wait For Line On Uart     timeout waiting for pong    testerId=${ping}    timeout=30
