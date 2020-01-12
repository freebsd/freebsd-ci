#!/usr/local/bin/python

import re
import sys

import pexpect

def forsend(child, s):
    for c in s:
        child.send(c)
    child.sendline()

cmd = "qemu-system-riscv64 -machine virt -m 2048M -smp 2 -nographic -kernel kernel.bin -bios /usr/local/share/opensbi/platform/qemu/virt/firmware/fw_jump.elf -drive file=./riscv.img,format=raw,id=hd0 -device virtio-blk-device,drive=hd0"
child = pexpect.spawnu(cmd)
child.logfile = sys.stdout
child.delaybeforesend = 0.5

child.expect(re.compile("^login:", re.MULTILINE), timeout=600)
forsend(child, "root")

child.expect("root@freebsd:~ #", timeout=300)
forsend(child, "shutdown -p now")

child.expect("Uptime:.*", timeout=600)
