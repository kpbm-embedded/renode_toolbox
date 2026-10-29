*** Settings ***
Documentation     Prebuilt Zephyr images from the Renode Zephyr dashboard (ELF + generated .repl + .resc) for the
...               user's boards, run on the pinned Renode 1.17.0. example.sh fetches them (sha256-checked) and
...               writes local .resc copies without the dashboard's log/asciinema/profiler lines.
Suite Setup       Setup
Suite Teardown    Teardown
Test Teardown     Test Teardown
Resource          ${RENODEKEYWORDS}

*** Keywords ***
Boot Dashboard Sample
    [Arguments]    ${board}    ${sample}    ${uart}
    Execute Command           $bin=@${EX_OUT}/${board}/${sample}.elf
    Execute Command           include @${EX_OUT}/${board}/${sample}.resc
    Create Terminal Tester    sysbus.${uart}    timeout=20    defaultPauseEmulation=True
    Register Failing Uart String    ZEPHYR FATAL ERROR

Shell Should Name The Board
    [Arguments]    ${board}    ${uart}    ${name}
    Boot Dashboard Sample     ${board}    shell_module    ${uart}
    Write Char Delay          0.01
    Wait For Prompt On Uart   uart:~$
    Write Line To Uart
    Wait For Prompt On Uart   uart:~$
    Write Line To Uart        demo board
    Wait For Line On Uart     ${name}

Hello World Should Print
    [Arguments]    ${board}    ${uart}    ${name}
    Boot Dashboard Sample     ${board}    hello_world    ${uart}
    Wait For Line On Uart     Hello World! ${name}

*** Test Cases ***
BlackPill F411 Shell
    Shell Should Name The Board    blackpill_f411ce    usart1    blackpill_f411ce

WeAct G431 Core Shell
    Shell Should Name The Board    weact_stm32g431_core    usart2    weact_stm32g431_core

STM32H7 Renode Reference Board Shell
    Shell Should Name The Board    stm32h7_renode_reference_board    usart2    stm32h7_renode_reference_board

Raspberry Pi Pico Hello World
    Hello World Should Print    rpi_pico    uart0    rpi_pico

i.MX 8M Plus Cortex-M7 Hello World
    Hello World Should Print    imx8mp_evk_mimx8ml8_m7    uart4    imx8mp_evk
