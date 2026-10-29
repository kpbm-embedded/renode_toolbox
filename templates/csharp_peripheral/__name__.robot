*** Settings ***
Documentation     @NAME@: test bench for a C# peripheral compiled by Renode at run time (no firmware needed).
...               Run: ./renode-box robot <dir>/@NAME@/@NAME@.robot
Suite Setup       Setup
Suite Teardown    Teardown
Test Teardown     Test Teardown
Resource          ${RENODEKEYWORDS}

*** Variables ***
${BASE}           0x40081000

*** Keywords ***
Create Machine
    Execute Command           include @${CURDIR}/@NAME@.cs
    Execute Command           mach create "@NAME@"
    Execute Command           machine LoadPlatformDescription @platforms/cpus/stm32f412.repl
    Execute Command           machine LoadPlatformDescriptionFromString "dut: Miscellaneous.@NAME@ @ sysbus ${BASE} { IRQ -> nvic@60 }"

Read Reg
    [Arguments]               ${offset}
    ${v}=                     Execute Command    sysbus ReadDoubleWord ${${BASE} + ${offset}}
    ${n}=                     Convert To Integer    ${v.strip()}
    RETURN                    ${n}

*** Test Cases ***
Start Should Compute And Set Done
    Create Machine
    Execute Command           sysbus WriteDoubleWord ${${BASE} + 0x8} 21
    Execute Command           sysbus WriteDoubleWord ${${BASE} + 0x0} 1
    ${v}=                     Read Reg    0xC
    Should Be Equal As Integers    ${v}    42
    ${s}=                     Read Reg    0x4
    Should Be Equal As Integers    ${s}    1

Done Should Be Write One To Clear
    Create Machine
    Execute Command           sysbus WriteDoubleWord ${${BASE} + 0x0} 1
    Execute Command           sysbus WriteDoubleWord ${${BASE} + 0x4} 1
    ${s}=                     Read Reg    0x4
    Should Be Equal As Integers    ${s}    0

IRQ Should Follow Done When Enabled
    Create Machine
    Execute Command           sysbus WriteDoubleWord ${${BASE} + 0x0} 3
    ${irq}=                   Execute Command    sysbus.dut IRQ
    Should Be Equal           ${irq.strip()}    GPIO: set
    Execute Command           sysbus WriteDoubleWord ${${BASE} + 0x4} 1
    ${irq}=                   Execute Command    sysbus.dut IRQ
    Should Be Equal           ${irq.strip()}    GPIO: unset
