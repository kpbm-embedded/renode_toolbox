#!/usr/bin/env python3
"""Drive Renode's server-mode WebSocket API like System Designer / the VS Code extension / renode-ui do:
load the BlackPill F411 example, list machines/UARTs/LEDs/buttons, run, press KEY, read the UART log file.
Usage: api_test.py PORT EX_DIR BLACKPILL_BUILD_DIR OUT_DIR"""
import asyncio
import os
import sys
import time

sys.path.insert(0, os.path.join(os.environ["RENODE_BOX_ROOT"], "lib"))
from ws_client import connect  # noqa: E402

port, ex_dir, elf_dir, out = int(sys.argv[1]), sys.argv[2], sys.argv[3], sys.argv[4]
uart_log = os.path.join(out, "usart1.txt")


def check(cond, what):
    print(f"{'ok  ' if cond else 'FAIL'}  {what}")
    if not cond:
        raise SystemExit(1)


async def wait_uart(text, timeout=30):
    end = time.time() + timeout
    while time.time() < end:
        if os.path.exists(uart_log) and text in open(uart_log, errors="replace").read():
            return True
        await asyncio.sleep(0.2)
    return False


async def main():
    ws, s = await connect("127.0.0.1", port, 30)
    try:
        await s.request("status")
        ver = "".join(await s.monitor("version"))
        check("1.17.0" in ver, f"exec-monitor version: {ver.split(chr(10))[1].strip() if chr(10) in ver else ver!r}")
        bp = os.path.join(ex_dir, "..", "stm32f4_blackpill")
        await s.monitor(f"$ex_dir=@{bp}", f"$ex_out=@{elf_dir}", f"include @{bp}/blackpill_f411.resc",
                        f"sysbus.usart1 CreateFileBackend @{uart_log} true")
        check(await s.renode("machines") == ["blackpill"], "exec-renode machines -> ['blackpill']")
        uarts = await s.renode("uarts", machine="blackpill")
        check("sysbus.usart1" in uarts, f"uarts: {len(uarts)} incl. sysbus.usart1")
        check(await s.renode("leds", machine="blackpill") == ["sysbus.gpioPortC.led"], "leds -> sysbus.gpioPortC.led")
        check(await s.renode("buttons", machine="blackpill") == ["sysbus.gpioPortA.button"], "buttons -> sysbus.gpioPortA.button")
        await s.monitor("start")
        check(await wait_uart("Hello from BlackPill F411"), "firmware banner in the UART file backend")
        check(await wait_uart("blink 2"), "firmware runs (blink 2)")
        await s.renode("button-set", machine="blackpill", peripheral="sysbus.gpioPortA.button", value=True)
        check(await wait_uart("KEY pressed"), "exec-renode button-set true -> firmware prints KEY pressed")
        await s.renode("button-set", machine="blackpill", peripheral="sysbus.gpioPortA.button", value=False)
        state = "".join(await s.monitor("sysbus.gpioPortC.led State"))
        check("True" in state or "False" in state, "LED state readable through exec-monitor")
        listing = await s.request("fs/list", {"args": ["."]})
        check(isinstance(listing, list), f"fs/list of the work dir ({len(listing)} entries)")
        reply = "".join(await s.monitor("no_such_command_xyz"))
        check("No such command" in reply or "error" in reply.lower(), "unknown monitor command: error text comes back")
        await s.monitor("pause")
    finally:
        await ws.close()
    print("server mode API: all checks passed")


asyncio.run(main())
