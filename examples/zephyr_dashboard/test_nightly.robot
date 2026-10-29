*** Settings ***
Documentation     Prebuilt Zephyr images from the Renode Zephyr dashboard (ELF + generated .repl + .resc) for the
...               user's boards, run on the dated Renode nightly (renode-nightly):
...               1.17.0 has no ESP32_USBSerialJTAG model. example.sh fetches them (sha256-checked) and
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
WeAct ESP32-S3 Mini Hello World
    Hello World Should Print    weact_esp32s3_mini_esp32s3_procpu    usbserial    weact_esp32s3_mini

