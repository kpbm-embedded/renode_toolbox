*** Settings ***
Documentation     RISC-V bare-metal on Renode: K210 (rv64) and LiteX VexRiscv (rv32).
Suite Setup       Setup
Suite Teardown    Teardown
Test Teardown     Test Teardown
Resource          ${RENODEKEYWORDS}

*** Keywords ***
Run Board
    [Arguments]               ${resc}
    Execute Command           $ex_dir=@${EX_DIR}
    Execute Command           $ex_out=@${EX_OUT}
    Execute Command           include @${EX_DIR}/${resc}
    Create Terminal Tester    sysbus.uart    defaultPauseEmulation=True

*** Test Cases ***
Should Run On The K210
    Run Board                 k210.resc
    Wait For Line On Uart     Hello from Kendryte K210
    Wait For Line On Uart     ISA: rv64.*i.*m    treatAsRegex=true
    Wait For Line On Uart     done

Should Run On LiteX VexRiscv
    Run Board                 litex.resc
    Wait For Line On Uart     Hello from LiteX VexRiscv
    Wait For Line On Uart     ISA: rv32
    Wait For Line On Uart     done
