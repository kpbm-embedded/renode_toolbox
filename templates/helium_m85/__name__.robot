*** Settings ***
Documentation     @NAME@: MVE kernels give the same results as plain C on the Cortex-M85 model; an instruction
...               Renode does not implement would abort the CPU ("Unsupported opcode") and the lines would never come.
...               Run: ./renode-box robot <dir>/@NAME@/@NAME@.robot   (build first: ./renode-box run make -C <dir>/@NAME@)
Suite Setup       Setup
Suite Teardown    Teardown
Test Teardown     Test Teardown
Resource          ${RENODEKEYWORDS}

*** Variables ***
${ELF}            ${CURDIR}/build/@NAME@.elf

*** Test Cases ***
MVE Kernels Match Scalar C
    Execute Command           $elf=@${ELF}
    Execute Command           include @${CURDIR}/@NAME@.resc
    Create Terminal Tester    sysbus.dbg_uart    defaultPauseEmulation=True    timeout=10
    Create Log Tester         1
    Wait For Line On Uart     @NAME@: Helium MVE on Cortex-M85
    Wait For Line On Uart     dot_q15 .* MATCH      treatAsRegex=true
    Wait For Line On Uart     vqadd_s32 .* MATCH    treatAsRegex=true
    Wait For Line On Uart     vfma_f32 .* MATCH     treatAsRegex=true
    Wait For Line On Uart     done
    Should Not Be In Log      Unsupported opcode
