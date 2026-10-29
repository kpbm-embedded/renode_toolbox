*** Settings ***
Documentation     Negative paths: HardFault reported by the firmware, unmapped access seen in Renode's log
...               (Log Tester), and how to assert that something does NOT happen or that a wait must fail.
Suite Setup       Setup
Suite Teardown    Teardown
Test Teardown     Test Teardown
Resource          ${RENODEKEYWORDS}

*** Keywords ***
Create Machine
    Execute Command           $ex_dir=@${EX_DIR}
    Execute Command           $ex_out=@${EX_OUT}
    Execute Command           include @${EX_DIR}/fault.resc
    Create Terminal Tester    sysbus.usart1    defaultPauseEmulation=True
    Wait For Line On Uart     fault demo

*** Test Cases ***
Undefined Instruction Should End In The HardFault Handler
    Create Machine
    Write Char On Uart        u
    ${l}=                     Wait For Line On Uart    HARDFAULT pc=(0x[0-9a-f]+) cfsr=(0x[0-9a-f]+)    treatAsRegex=true
    # CFSR.UNDEFINSTR is bit 16; the stacked PC is inside do_undefined
    Should Be True            int("${l.Groups[1]}", 16) & (1 << 16)
    ${fn}=                    Execute Command    sysbus FindSymbolAt ${l.Groups[0]}
    Should Contain            ${fn}    do_undefined

Unmapped Access Should Show In The Renode Log
    Create Machine
    Create Log Tester         1
    Write Char On Uart        m
    Wait For Line On Uart     unmapped read gave 0x00000000
    Wait For Log Entry        ReadDoubleWord from non existing peripheral at 0x30000000

Assert Message Should Be Caught
    Create Machine
    Write Char On Uart        a
    Wait For Line On Uart     ASSERT failed: two + two == 5

Nothing Bad Should Happen Without Input
    Create Machine
    Should Not Be On Uart     HARDFAULT    timeout=0.5
    Run Keyword And Expect Error    *Terminal tester failed*    Wait For Line On Uart    ASSERT    timeout=0.2
