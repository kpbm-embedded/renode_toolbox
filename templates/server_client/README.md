# @NAME@: client for Renode's server mode (from `./renode-box new server_client`)

Renode 1.17 has a built-in WebSocket API (`renode --server-mode`, endpoint `ws://<host>:<port>/proxy`, JSON
protocol 1.5.0). `renode --ui`, Antmicro's System Designer ("Run locally") and the VS Code extension use it; this
client uses it from Python, headless: create a machine, load a platform, list what a GUI would show (UARTs, LEDs,
buttons, sensors), load an ELF, run, and read a UART through a file backend.

| File | What |
|---|---|
| `@NAME@.py` | the client (protocol helpers from renode-box's `lib/ws_client.py`) |
| `@NAME@.repl` | nRF52840 with the legacy UART, for the prebuilt Zephyr shell that `test.sh` runs (offline) |
| `test.sh` | starts a server on a free port, runs the client against it, stops the server |

```sh
./renode-box run bash <dir>/@NAME@/test.sh
./renode-box server --port 21234 &                    # a server to keep (Ctrl-C or `quit` over the API stops it)
./renode-box run python <dir>/@NAME@/@NAME@.py --port 21234 --repl platforms/cpus/stm32f412.repl \
    --elf fw.elf --uart sysbus.usart1 --expect "hello"
```
Warning: Renode 1.17 binds the server to all interfaces (0.0.0.0) and has no option to change it; the API can load
files and run monitor commands. Keep the port behind a firewall on untrusted networks.
