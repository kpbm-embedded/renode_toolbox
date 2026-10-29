*** Settings ***
Documentation     Save the whole emulation to a file and load it back: state (RAM, CPU, peripherals) is restored.
Suite Setup       Setup
Suite Teardown    Teardown
Test Teardown     Test Teardown
Resource          ${RENODEKEYWORDS}
Library           OperatingSystem

*** Variables ***
${SNAP}           ${EX_OUT}/tick5.save

*** Keywords ***
Create Machine
    Execute Command           $ex_dir=@${EX_DIR}
    Execute Command           $ex_out=@${EX_OUT}
    Execute Command           include @${EX_DIR}/snapshot.resc
    Create Terminal Tester    sysbus.usart1    defaultPauseEmulation=True

*** Test Cases ***
Should Continue From The Saved State
    Create Machine
    Wait For Line On Uart     tick 5
    Execute Command           Save @${SNAP}
    File Should Exist         ${SNAP}
    Wait For Line On Uart     tick 9
    ${n}=                     Execute Command    sysbus ReadDoubleWord `sysbus GetSymbolAddress "g_ticks"`
    Should Be True            int("""${n}""".strip(), 16) >= 9
    Execute Command           Load @${SNAP}
    Execute Command           mach set 0
    ${n}=                     Execute Command    sysbus ReadDoubleWord `sysbus GetSymbolAddress "g_ticks"`
    Should Be Equal As Integers    ${n.strip()}    5
    Create Terminal Tester    sysbus.usart1    defaultPauseEmulation=True
    Wait For Line On Uart     tick 6
    Should Not Be On Uart     snapshot demo boot    timeout=0.5

Should Restore The Same Snapshot Twice
    Create Machine
    Wait For Line On Uart     tick 5
    Execute Command           Save @${SNAP}
    FOR    ${i}    IN RANGE    2
        Execute Command           Load @${SNAP}
        Execute Command           mach set 0
        Create Terminal Tester    sysbus.usart1    defaultPauseEmulation=True
        Wait For Line On Uart     tick 6
    END
