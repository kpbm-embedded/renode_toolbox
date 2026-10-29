"""Host-side client for a Renode UART exposed on TCP (CreateServerSocketTerminal).

Usage: python host_client.py <port> [--timeout S]
Waits for the firmware prompt, sends a line, checks the echo and the reply, sends a
second line and checks that the LED counter moved on (the firmware kept running).
Exit 0 on success. The same code works against ser2net/a real board's TCP bridge."""
import argparse
import re
import socket
import sys
import time


def read_until(sock, pattern, timeout):
    buf = b""
    end = time.monotonic() + timeout
    while time.monotonic() < end:
        sock.settimeout(max(0.05, end - time.monotonic()))
        try:
            chunk = sock.recv(4096)
        except socket.timeout:
            break
        if not chunk:
            break
        buf += chunk
        m = re.search(pattern, buf)
        if m:
            return buf, m
    raise TimeoutError(f"no {pattern!r} within {timeout}s; got {buf!r}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("port", type=int)
    ap.add_argument("--timeout", type=float, default=30)
    a = ap.parse_args()
    with socket.create_connection(("127.0.0.1", a.port), timeout=a.timeout) as s:
        read_until(s, rb"> ", a.timeout)
        print("prompt seen")
        s.sendall(b"hello-from-host\r")
        _, m = read_until(s, rb"hello-from-host\r?\n+led toggles so far: (\d+)", a.timeout)
        first = int(m.group(1))
        print(f"echo ok, led toggles {first}")
        time.sleep(1.0)  # host time: the emulation keeps running meanwhile
        s.sendall(b"again\r")
        _, m = read_until(s, rb"again\r?\n+led toggles so far: (\d+)", a.timeout)
        second = int(m.group(1))
        print(f"second reply ok, led toggles {second}")
        if second <= first:
            print("FAIL: the firmware did not advance between the two lines")
            return 1
    print("socket UART check passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
