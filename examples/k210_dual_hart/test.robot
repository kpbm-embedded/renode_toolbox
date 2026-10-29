*** Settings ***
Documentation     Two harts on one SoC: both run, atomics (amoadd) keep a shared counter exact, per-hart CPU state.
Suite Setup       Setup
Suite Teardown    Teardown
Test Teardown     Test Teardown
Resource          ${RENODEKEYWORDS}

*** Keywords ***
Create Machine
    Execute Command           $ex_dir=@${EX_DIR}
    Execute Command           $ex_out=@${EX_OUT}
    Execute Command           include @${EX_DIR}/k210_dual.resc
    Create Terminal Tester    sysbus.uart    defaultPauseEmulation=True

*** Test Cases ***
Hart 1 Should Do The Work
    Create Machine
    Wait For Line On Uart     hart 0 up
    Wait For Line On Uart     hart 1 found 2262 primes below 20000    timeout=30

Atomic Counter Should Be Exact
    Create Machine
    Wait For Line On Uart     shared count 10000 (atomic ok)    timeout=30
    Wait For Line On Uart     hart 0 ran in parallel

Both Harts Should Exist In The Monitor
    Create Machine
    Wait For Line On Uart     atomic ok    timeout=30
    # the .repl names them cpu1 and cpu2; their hart ids are 0 and 1
    ${h0}=                    Execute Command    cpu1 HartId
    ${h1}=                    Execute Command    cpu2 HartId
    Should Be Equal As Integers    ${h0.strip()}    0
    Should Be Equal As Integers    ${h1.strip()}    1
    # hart 1 finished its work and sleeps in wfi; both PCs are inside the firmware (RAM @0x80000000)
    ${pc}=                    Execute Command    cpu2 PC
    Should Start With         ${pc.strip()}    0x800
