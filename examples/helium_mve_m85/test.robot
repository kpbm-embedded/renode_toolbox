*** Settings ***
Documentation     MVE integer, predicated and floating-point kernels give the same result as plain C on the
...               Cortex-M85 model; an unsupported instruction would abort the CPU and miss the lines.
Suite Setup       Setup
Suite Teardown    Teardown
Test Teardown     Test Teardown
Resource          ${RENODEKEYWORDS}

*** Test Cases ***
MVE Kernels Match Scalar C
    Execute Command           $ex_dir=@${EX_DIR}
    Execute Command           $ex_out=@${EX_OUT}
    Execute Command           include @${EX_DIR}/helium.resc
    Create Terminal Tester    sysbus.dbg_uart    defaultPauseEmulation=True    timeout=10
    Create Log Tester         1
    Wait For Line On Uart     Helium MVE on Cortex-M85
    Wait For Line On Uart     dot_q15 .* MATCH      treatAsRegex=true
    Wait For Line On Uart     vqadd_s32 .* MATCH    treatAsRegex=true
    Wait For Line On Uart     vfma_f32 .* MATCH     treatAsRegex=true
    Wait For Line On Uart     done
    Should Not Be In Log      Unsupported opcode
