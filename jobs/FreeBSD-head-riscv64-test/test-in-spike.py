#!/usr/local/bin/python

import pexpect
import sys

def forsend(child, s):
    for c in s:
        child.send(c)
    child.sendline()

cmd = "spike -m2048 -p2 ./bbl"
child = pexpect.spawn(cmd)
child.logfile = sys.stdout
child.delaybeforesend = 0.5

child.expect("login:", timeout=600)
forsend(child, "root")

child.expect("#", timeout=300)
forsend(child, "shutdown -p now")

child.expect("Uptime:.*", timeout=600)
