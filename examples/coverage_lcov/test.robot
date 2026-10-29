*** Settings ***
Documentation     Two test cases, one binary execution trace each (PCAndOpcode, gzip). example.sh turns them
...               into LCOV .info files, merges them and checks line coverage.
Suite Setup       Setup
Suite Teardown    Teardown
Test Teardown     Test Teardown
Resource          ${RENODEKEYWORDS}

*** Keywords ***
Start Traced Machine
    [Arguments]    ${name}
    Execute Command           $ex_dir=@${EX_DIR}
    Execute Command           $ex_out=@${EX_OUT}
    Execute Command           include @${EX_DIR}/cov.resc
    Execute Command           cpu CreateExecutionTracing "tracer" @${EX_OUT}/trace_${name}.bin.gz PCAndOpcode true true
    Create Terminal Tester    sysbus.usart1    defaultPauseEmulation=True
    Wait For Prompt On Uart   cmd>

*** Test Cases ***
LED Command
    Start Traced Machine      led
    Write Line To Uart        l    waitForEcho=false
    Wait For Line On Uart     led toggled

Status And Unknown Commands
    Start Traced Machine      status
    Write Line To Uart        s    waitForEcho=false
    Wait For Line On Uart     status ok
    Write Line To Uart        q    waitForEcho=false
    Wait For Line On Uart     unknown command q
