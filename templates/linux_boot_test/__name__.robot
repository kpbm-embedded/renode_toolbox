*** Settings ***
Documentation     @NAME@: boot embedded Linux in Renode, log in on the console, run commands.
...               Run: ./renode-box robot <dir>/@NAME@/@NAME@.robot  [--variable VMLINUX:... --variable DTB:... --variable ROOTFS:...]
Suite Setup       Setup
Suite Teardown    Teardown
Test Teardown     Test Teardown
Resource          ${RENODEKEYWORDS}

*** Variables ***
${DEMOS}          %{RENODE_BOX_DEMOS}
${VMLINUX}        ${EMPTY}
${DTB}            ${EMPTY}
${ROOTFS}         ${EMPTY}
${UART}           sysbus.uart0
${LOGIN}          buildroot login:
${USER}           root
${PROMPT}         \#${SPACE}

*** Keywords ***
Boot Linux
    Execute Command           $demos=@${DEMOS}
    IF    "${VMLINUX}" != ""
        Execute Command       $vmlinux=@${VMLINUX}
    END
    IF    "${DTB}" != ""
        Execute Command       $dtb=@${DTB}
    END
    IF    "${ROOTFS}" != ""
        Execute Command       $rootfs=@${ROOTFS}
    END
    Execute Command           include @${CURDIR}/@NAME@.resc
    Create Terminal Tester    ${UART}    defaultPauseEmulation=True

Log In
    Wait For Prompt On Uart   ${LOGIN}    timeout=120
    Write Line To Uart        ${USER}
    Wait For Prompt On Uart   ${PROMPT}

*** Test Cases ***
Should Boot The Kernel
    Boot Linux
    Wait For Line On Uart     Booting Linux on physical CPU 0x0
    Wait For Line On Uart     Freeing unused kernel    timeout=120

Should Log In And Run Commands
    Boot Linux
    Log In
    Write Line To Uart        uname -m
    Wait For Line On Uart     armv7l
    Write Line To Uart        cat /proc/cpuinfo | grep -c processor
    Wait For Line On Uart     ^[12]$    treatAsRegex=true
    Write Line To Uart        true; echo "status $?"
    Wait For Line On Uart     status 0
