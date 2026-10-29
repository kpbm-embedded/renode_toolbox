*** Settings ***
Documentation     @NAME@: two machines in one emulation, UART hub between them, one tester per machine.
...               Run: ./renode-box robot <dir>/@NAME@/@NAME@.robot   (build first: ./renode-box run make -C <dir>/@NAME@)
Suite Setup       Setup
Suite Teardown    Teardown
Test Teardown     Test Teardown
Resource          ${RENODEKEYWORDS}

*** Keywords ***
Create Nodes
    Execute Command           include @${CURDIR}/@NAME@.resc
    ${ping}=                  Create Terminal Tester    sysbus.usart1    machine=ping    defaultPauseEmulation=True
    ${pong}=                  Create Terminal Tester    sysbus.usart1    machine=pong    defaultPauseEmulation=True
    Set Test Variable         ${ping}
    Set Test Variable         ${pong}

*** Test Cases ***
Pong Should Answer Ping
    Create Nodes
    Wait For Line On Uart     rx: ping 1    testerId=${pong}
    Wait For Line On Uart     got: pong 1    testerId=${ping}
    Wait For Line On Uart     got: pong 2    testerId=${ping}

Ping Should Notice A Broken Link
    Create Nodes
    Wait For Line On Uart     got: pong 1    testerId=${ping}
    Execute Command           mach set "pong"
    Execute Command           connector Disconnect sysbus.usart2 link
    Wait For Line On Uart     timeout waiting for pong    testerId=${ping}    timeout=30
