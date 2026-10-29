*** Settings ***
Documentation     @NAME@: test bench for a Python peripheral model, driven from the monitor (no firmware needed).
...               Run: ./renode-box robot <dir>/@NAME@/@NAME@.robot
Suite Setup       Setup
Suite Teardown    Teardown
Test Teardown     Test Teardown
Resource          ${RENODEKEYWORDS}

*** Variables ***
${BASE}           0x40080000

*** Keywords ***
Create Machine
    Execute Command           mach create "@NAME@"
    Execute Command           machine LoadPlatformDescription @${CURDIR}/@NAME@.repl

Read Reg
    [Arguments]               ${offset}
    ${v}=                     Execute Command    sysbus ReadDoubleWord ${${BASE} + ${offset}}
    ${n}=                     Convert To Integer    ${v.strip()}
    RETURN                    ${n}

*** Test Cases ***
ID Register Should Read Back
    Create Machine
    ${id}=                    Read Reg    0x0
    Should Be Equal As Integers    ${id}    0x5E450001

Value Set By The Test Should Be Read Back
    Create Machine
    Execute Command           sysbus WriteDoubleWord ${${BASE} + 0x10} 1234
    ${v}=                     Read Reg    0x4
    Should Be Equal As Integers    ${v}    1234

Samples Should Be Counted
    Create Machine
    FOR    ${i}    IN RANGE    3
        Execute Command       sysbus WriteDoubleWord ${${BASE} + 0x8} 1
    END
    ${n}=                     Read Reg    0xC
    Should Be Equal As Integers    ${n}    3
