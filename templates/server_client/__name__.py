#!/usr/bin/env python3
"""@NAME@: a client for Renode's server mode (renode --server-mode, Renode 1.17's built-in WebSocket API, the one
renode-ui, System Designer and the VS Code extension use). It loads a platform, lists what the GUI would show
(machines, UARTs, LEDs, buttons, sensors), runs, and reads the UART through a file backend.

  ./renode-box server --port 21234 &                       # or: renode --server-mode --server-mode-port 21234
  ./renode-box run python @NAME@.py --port 21234 [--repl platforms/cpus/stm32f412.repl] [--elf fw.elf --uart sysbus.usart1]

Protocol helpers come from renode-box's lib/ws_client.py ($RENODE_BOX_ROOT/lib)."""
import argparse
import asyncio
import os
import sys
import tempfile
import time

sys.path.insert(0, os.path.join(os.environ.get("RENODE_BOX_ROOT", ""), "lib"))
from ws_client import connect  # noqa: E402


async def run(a):
    ws, s = await connect(a.host, a.port, 30)
    try:
        print("version:", "".join(await s.monitor("version")).split("\n")[1].strip())
        await s.monitor('mach create "@NAME@"', f"machine LoadPlatformDescription @{a.repl}")
        print("machines:", await s.renode("machines"))
        for what in ("uarts", "leds", "buttons", "sensors"):
            print(f"{what}:", await s.renode(what, machine="@NAME@"))
        if a.elf:
            with tempfile.TemporaryDirectory(prefix="srvclient.") as td:   # UART file backend, removed afterwards
                log = os.path.join(td, "uart.txt")
                await s.monitor(f"sysbus LoadELF @{a.elf}", f"{a.uart} CreateFileBackend @{log} true", "start")
                end = time.time() + a.seconds
                while time.time() < end and not (os.path.exists(log) and a.expect in open(log, errors="replace").read()):
                    await asyncio.sleep(0.2)
                text = open(log, errors="replace").read() if os.path.exists(log) else ""
                await s.monitor("pause")
            print(f"uart ({a.uart}):", text.strip().splitlines()[:5])
            if a.expect and a.expect not in text:
                raise SystemExit(f"@NAME@: '{a.expect}' not seen on {a.uart}")
        await s.monitor('mach clear') if a.clear else None
    finally:
        await ws.close()


def main():
    p = argparse.ArgumentParser(description="@NAME@: Renode server-mode client")
    p.add_argument("--host", default="127.0.0.1")
    p.add_argument("--port", type=int, default=21234)
    p.add_argument("--repl", default="platforms/cpus/stm32f412.repl")
    p.add_argument("--elf")
    p.add_argument("--uart", default="sysbus.usart1")
    p.add_argument("--expect", default="")
    p.add_argument("--seconds", type=float, default=20)
    p.add_argument("--clear", action="store_true", help="remove the machine at the end")
    asyncio.run(run(p.parse_args()))


if __name__ == "__main__":
    main()
