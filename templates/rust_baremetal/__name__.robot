*** Settings ***
Documentation     @NAME@: no_std Rust (toolchain of 32_17_embedded_rust) on two Renode boards: Arm and RISC-V.
...               Run: ./renode-box robot <dir>/@NAME@/@NAME@.robot   (build first: ./renode-box run make -C <dir>/@NAME@)
Suite Setup       Setup
Suite Teardown    Teardown
Test Teardown     Test Teardown
Resource          ${RENODEKEYWORDS}

*** Keywords ***
Create Machine
    [Arguments]               ${resc}
    Execute Command           include @${CURDIR}/${resc}
    Create Terminal Tester    sysbus.usart1    defaultPauseEmulation=True

*** Test Cases ***
Should Run On The BlackPill
    Create Machine            @NAME@_blackpill.resc
    Wait For Line On Uart     Hello from Rust on BlackPill F411 (thumbv7em)
    Wait For Line On Uart     data 7 bss 0
    Wait For Line On Uart     fib(10) = 55

Should Blink The LED From Rust
    Create Machine            @NAME@_blackpill.resc
    Create LED Tester         sysbus.gpioPortC.led    defaultTimeout=2
    Wait For Line On Uart     fib(2) = 1
    Assert LED State          true
    Wait For Line On Uart     fib(3) = 2
    Assert LED State          false

Panic Handler Should Report Message And Location
    Create Machine            @NAME@_blackpill.resc
    Wait For Line On Uart     fib(2) = 1
    Execute Command           sysbus.gpioPortA.button Press
    Wait For Line On Uart     PANIC: KEY pressed at n=2 at src/main.rs:    timeout=5

Should Run On The CH32V203-like RISC-V Board
    Create Machine            @NAME@_ch32v203.resc
    Wait For Line On Uart     Hello from Rust on CH32V203-like (riscv32imac)
    Wait For Line On Uart     data 7 bss 0
    Wait For Line On Uart     fib(47) = 2971215073
