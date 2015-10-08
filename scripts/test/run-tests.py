# Copyright (c) 2014, Craig Rodrigues <rodrigc@FreeBSD.org>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice unmodified, this list of conditions, and the following
#    disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
# NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#
#
# RUN KYUA TESTS INSIDE WITH BHYVE
#
# The following program::
#   (1) takes a an image
#   (2) boots it
#   (3) runs tests in /usr/tests
#
from __future__ import print_function
from optparse import OptionParser
import atexit
import getopt
import json
import os
import os.path
import pexpect
import sys
import subprocess
import fabric.api

test_config = None
test_config_file = None
sentinel_file = None

def usage(argv):
    print("Usage:")
    print("    %s -f [JSON config file]" % argv[0])


def main(argv):

    try:
        opts, args = getopt.getopt(sys.argv[1:], "f:")
    except getopt.GetoptError as err:
        sys.exit(2)

    global test_config
    global test_config_file

    for o, a in opts:
        if o == "-f":
            test_config_file = a
        else:
            assert False, "unhandled option"

    if test_config_file is None:
        usage(argv)
        sys.exit(1)

    config_file = open(test_config_file, "r")
    test_config = json.load(config_file)
    config_file.close()
    checkpreReqBhyve()
    runTest()

def runTest():
    global test_config
    global test_config_file

    home = os.path.expanduser("~")
    known_hosts = "%s/.ssh/known_hosts" % (home)

    # Create the bridge interface if it does not exist.
    # Configure the bridge with an IP address.
    print(["ifconfig", test_config['bridge']])
    ret = subprocess.call(["ifconfig", test_config['bridge']])
    if ret != 0:
        ret = subprocess.call(["ifconfig", test_config['bridge'], "create"])
        if ret != 0:
            sys.exit(ret)
        ret = subprocess.call(["ifconfig", test_config['bridge'], "inet", "%s/24" % test_config['bridge_ip']])
        if ret != 0:
            sys.exit(ret)

    # Create the tap interface if it does not exist.
    # Add the tap interface to the bridge.
    ret = subprocess.call(["ifconfig", test_config['tap']])
    if ret != 0:
        ret = subprocess.call(["ifconfig", test_config['tap'], "create"])
        if ret != 0:
            sys.exit(ret)
        ret = subprocess.call(["ifconfig", test_config['bridge'], "addm", test_config['tap']])
        if ret != 0:
            sys.exit(ret)

    cmd = "bhyvectl --destroy --vm=%s" % test_config['vm_name']
    print("")
    ret = os.system(cmd)

    cmd = "bhyveload -m %s -d %s %s" % \
          (test_config['ram'], test_config['disks'][0], test_config['vm_name'])
    print(cmd)
    child = pexpect.spawn(cmd)
    child.logfile = sys.stdout
    child.expect(pexpect.EOF, timeout=120)

    macaddress = ""
    if "mac" in test_config:
        macaddress = ",mac=%s" % test_config['mac']

    cmd = "bhyve -c 2 -m %s -AI -H -P -g 0 -s 0:0,hostbridge " \
          "-s 1:0,lpc -s 2:0,virtio-net,%s%s -s 3:0,ahci-hd,%s " \
          "-l com1,stdio %s"  % \
         (test_config['ram'], test_config['tap'], macaddress, \
          test_config['disks'][0], test_config['vm_name'])
    print(cmd)
    child2 = pexpect.spawn(cmd)
    child2.logfile = sys.stdout

    # Log into the VM via expect, and execute enough
    # commands to figure out the IP address.
    child2.expect(['login:'], timeout=1200)
    child2.sendline("root")
    child2.expect(['Password:'], timeout=1200)
    child2.sendline("test")
    child2.expect("# ")

    # Change the prompt to something more unique
    prompt = "kyuatestprompt # "
    child2.sendline("set prompt=\"%s\"" % (prompt))
    child2.expect(prompt)
    child2.expect(prompt)

    child2.sendline("ifconfig %s | grep 'inet '" % (test_config['interface']))
    child2.before = None
    child2.after = None
    i = child2.expect(['       inet ', prompt, pexpect.EOF])
    ip_address = None
    if i == 0:
        # matched "	inet 8.8.178.209 netmask 0xffffffe0 broadcast 8.8.178.223"
        i1 = child2.expect(['netmask ', prompt, pexpect.EOF])
        if i1 == 0:
            # matched "netmask 0xffffffe0 broadcast 8.8.178.223"
            ip_address = child2.before.strip()
            print("\nFound IP address: %s" % (ip_address))
            subprocess.call(["sed", "-i", "", "-e", "/%s/d" % (ip_address), known_hosts])

    if ip_address is None:
        print("\nDid not find IP address for %s" %  (test_config['interface']))
        child2.sendline("shutdown -p now")
        child2.expect(pexpect.EOF, timeout=1000)
    else:
        # If at this point we have figured out the IP address for
        # this host, then execute all subsequent commands over SSH
        # using the Python Fabric library.

        # Set global state used by Python Fabric library
        fabric.api.env.host_string = ip_address
        fabric.api.env.user = "root"
        fabric.api.env.password = "test"
        fabric.api.env.shell = "/bin/sh -c"
        fabric.api.env.warn_only = True

        # Execute commands over SSH.  We can more easily
        # grab the exit status code of executed commands over SSH,
        # compared to expect.
        with fabric.api.cd("/usr/tests"):
            fabric.api.run("kyua test")
            fabric.api.run("kyua report --verbose --results-filter passed,skipped,xfail,broken,failed  --output test-report.txt")
            fabric.api.run("kyua report-junit --output=test-report.xml")
            fabric.api.run("shutdown -p now")
            child2.expect(pexpect.EOF, timeout=1000)

def checkpreReqBhyve():
    # Check if Bhyve module is loaded, and if we ran the script as superuser.
    # If not, silently kill the application.
    euid = os.geteuid()
    if euid != 0:
        raise EnvironmentError("this script need to be run as root")
    ret = os.system("kldload -n vmm")
    if ret != 0:
        raise EnvironmentError("missing vmm.ko")
    ret = os.system("kldload -n if_tap")
    if ret != 0:
        raise EnvironmentError("missing if_tap.ko")

def cleanup():
    os.system("rm -f %s" % (sentinel_file))

if __name__ == "__main__":
    atexit.register(cleanup)
    main(sys.argv)
