*** Settings ***
Documentation     @NAME@: Renode GDB server + gdb in batch mode from a Robot test (breakpoints, backtrace, memory).
...               Run: ./renode-box robot <dir>/@NAME@/@NAME@.robot  [--variable ELF:<fw.elf> --variable GDB:riscv-none-elf-gdb]
Suite Setup       Setup
Suite Teardown    Teardown
Test Teardown     Test Teardown
Resource          ${RENODEKEYWORDS}
Library           Process
Library           Collections

*** Variables ***
${ELF}            %{RENODE_BOX_DEMOS}/zephyr_shell_nrf52840.elf-s_1110556-9653ab7fffe1427c50fa6b837e55edab38925681
${PLATFORM}       ${CURDIR}/@NAME@.repl
${GDB}            arm-none-eabi-gdb
${BREAK}          main

*** Keywords ***
Create Machine With GDB Server
    ${port}=                  Evaluate    random.randint(20000, 40000)    modules=random
    Set Test Variable         ${PORT}    ${port}
    Execute Command           mach create "@NAME@"
    Execute Command           machine LoadPlatformDescription @${PLATFORM}
    Execute Command           sysbus LoadELF @${ELF}
    # autostart: the emulation starts when gdb continues
    Execute Command           machine StartGdbServer ${PORT} true

Run GDB
    [Arguments]               @{commands}
    @{args}=                  Create List    -q    -batch    -nx    -ex    target remote :${PORT}
    FOR    ${c}    IN    @{commands}
        Append To List        ${args}    -ex    ${c}
    END
    ${r}=                     Run Process    ${GDB}    @{args}    ${ELF}    timeout=120s    stderr=STDOUT
    Log                       ${r.stdout}
    RETURN                    ${r.stdout}

*** Test Cases ***
Should Stop At The Breakpoint
    Create Machine With GDB Server
    ${out}=                   Run GDB    break ${BREAK}    continue    bt    detach
    # "Breakpoint 1, main" or "Breakpoint 1.2, main" when the symbol has several locations
    Should Match Regexp       ${out}    Breakpoint 1(\\.\\d+)?, ${BREAK}

Should Read Registers And Memory
    Create Machine With GDB Server
    ${out}=                   Run GDB    break ${BREAK}    continue    info registers pc    x/4xw $sp    detach
    Should Match Regexp       ${out}    pc\\s+0x[0-9a-f]+\\s+0x[0-9a-f]+ <${BREAK}
    Should Match Regexp       ${out}    0x2[0-9a-f]+.*:\\s+0x[0-9a-f]+
