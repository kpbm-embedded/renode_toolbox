*** Settings ***
Documentation     @NAME@: one binary execution trace per test case (PCAndOpcode, gzip) for line coverage.
...               Run all of it: ./renode-box run bash <dir>/@NAME@/test.sh  (robot + covflow: .info, merge, checks, Coverview)
Suite Setup       Setup
Suite Teardown    Teardown
Test Teardown     Test Teardown
Resource          ${RENODEKEYWORDS}

*** Variables ***
${ELF}            ${CURDIR}/build/@NAME@.elf
${TRACES}         ${CURDIR}/build/cov

*** Keywords ***
Start Traced Machine
    [Arguments]    ${name}
    Execute Command           $elf=@${ELF}
    Execute Command           include @${CURDIR}/@NAME@.resc
    Execute Command           cpu CreateExecutionTracing "tracer" @${TRACES}/${name}.bin.gz PCAndOpcode true true
    Create Terminal Tester    sysbus.usart1    defaultPauseEmulation=True
    Wait For Prompt On Uart   cmd>

*** Test Cases ***
Led
    Start Traced Machine      led
    Write Line To Uart        l    waitForEcho=false
    Wait For Line On Uart     led toggled

Count And Unknown
    Start Traced Machine      count
    Write Line To Uart        c    waitForEcho=false
    Wait For Line On Uart     count 1
    Write Line To Uart        c    waitForEcho=false
    Wait For Line On Uart     count 2
    Write Line To Uart        x    waitForEcho=false
    Wait For Line On Uart     unknown command x
