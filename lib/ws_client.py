#!/usr/bin/env python3
"""ws_client.py: small client for Renode's server-mode WebSocket API (renode --server-mode, Renode 1.17).

Protocol (version 1.5.0, the one renode-ws-proxy and the VS Code extension use): JSON requests
  {"version": "1.5.0", "action": A, "id": N, "payload": {...}}
answered by {"version", "status": "success"|"failure", "id": N, "data", "error"}. Events (no id) may arrive in
between. Actions used here: status, exec-monitor {commands: [...]}, exec-renode {command, args},
fs/list {args: [path]}. Endpoint: ws://<host>:<port>/proxy.

Usage (inside the env: ./renode-box run python lib/ws_client.py ...):
  ws_client.py --port P status
  ws_client.py --port P monitor 'mach create "m"' 'machine LoadPlatformDescription @platforms/cpus/stm32f412.repl'
  ws_client.py --port P renode machines
  ws_client.py --port P renode uarts '{"machine": "m"}'
  ws_client.py --port P fs-list .
Prints the response's data as JSON; exit 1 on a failure response or timeout.
"""
import argparse
import asyncio
import json
import sys

import websockets

VERSION = "1.5.0"


class Session:
    def __init__(self, ws, timeout):
        self.ws, self.timeout, self.next_id, self.events = ws, timeout, 1, []

    async def request(self, action, payload=None):
        rid = self.next_id
        self.next_id += 1
        await self.ws.send(json.dumps({"version": VERSION, "action": action, "id": rid, "payload": payload or {}}))
        while True:
            msg = json.loads(await asyncio.wait_for(self.ws.recv(), self.timeout))
            if msg.get("id") == rid:
                if msg.get("status") != "success":
                    raise RuntimeError(f"{action}: {msg.get('error') or msg}")
                return msg.get("data")
            if "event" in msg:
                self.events.append(msg)

    async def monitor(self, *commands):
        return await self.request("exec-monitor", {"commands": list(commands)})

    async def renode(self, command, **args):
        payload = {"command": command}
        if args:
            payload["args"] = args
        return await self.request("exec-renode", payload)


async def connect(host, port, timeout):
    ws = await websockets.connect(f"ws://{host}:{port}/proxy", open_timeout=timeout, max_size=None)
    return ws, Session(ws, timeout)


async def main_async(a):
    ws, s = await connect(a.host, a.port, a.timeout)
    try:
        if a.cmd == "status":
            data = await s.request("status")
        elif a.cmd == "monitor":
            data = await s.monitor(*a.args)
        elif a.cmd == "renode":
            data = await s.renode(a.args[0], **(json.loads(a.args[1]) if len(a.args) > 1 else {}))
        elif a.cmd == "fs-list":
            data = await s.request("fs/list", {"args": [a.args[0] if a.args else "."]})
        else:
            raise SystemExit(f"unknown command {a.cmd}")
    finally:
        await ws.close()
    print(json.dumps(data, indent=1))


def main():
    p = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    p.add_argument("--host", default="127.0.0.1")
    p.add_argument("--port", type=int, default=21234)
    p.add_argument("--timeout", type=float, default=30)
    p.add_argument("cmd", choices=["status", "monitor", "renode", "fs-list"])
    p.add_argument("args", nargs="*")
    a = p.parse_args()
    try:
        asyncio.run(main_async(a))
    except (OSError, RuntimeError, asyncio.TimeoutError, websockets.WebSocketException) as e:
        print(f"ws_client: {type(e).__name__}: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
