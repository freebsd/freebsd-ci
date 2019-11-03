#!/usr/local/bin/python

import re
import sys

import pexpect

def forsend(child, s):
    for c in s:
        child.send(c)
    child.sendline()

cmd = "qemu-system-riscv64 --machine virt -bios none -nographic -smp 2 -m 2048M -kernel ./bbl"
child = pexpect.spawn(cmd)
child.logfile = sys.stdout
child.delaybeforesend = 0.5

child.expect(re.compile("^login:", re.MULTILINE), timeout=600)
forsend(child, "root")

child.expect("#", timeout=300)
forsend(child, "shutdown -p now")

child.expect("Uptime:.*", timeout=600)
