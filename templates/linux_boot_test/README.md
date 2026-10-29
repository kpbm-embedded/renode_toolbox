# @NAME@: embedded Linux boot test (from `./renode-box new linux_boot_test`)

Defaults to the Zynq-7000 (Cortex-A9) buildroot images cached by `./renode-box install` (offline).
For your own Yocto/buildroot images on a Cortex-A9 class platform, pass them as variables; for another
SoC, change the `.repl` and the load addresses in `@NAME@.resc`.

```sh
./renode-box robot <dir>/@NAME@/@NAME@.robot
./renode-box robot <dir>/@NAME@/@NAME@.robot --variable VMLINUX:/path/vmlinux \
    --variable DTB:/path/board.dtb --variable ROOTFS:/path/rootfs.cpio --variable "LOGIN:myboard login:"
```
A boot takes about 15-20 s host time. Each test boots again (renode-test resets between tests); for
long suites boot once and use snapshots (`zephyr_snapshot_test` template shows how).
