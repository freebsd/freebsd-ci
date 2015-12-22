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

# EXTRACT TEST LOGS FROM BHYVE VM
#
# The following program::
#   (1) takes a UFS image
#   (2) mounts it
#   (3) extracts test logs from /usr/tests directory
#

from __future__ import print_function
from optparse import OptionParser
import atexit
import getopt
import json
import os
import sys
import tempfile

test_config = None
test_config_file = None
sentinel_file = None
temp_dir = None

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
    global sentinel_file
    global temp_dir

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

    cmd = "mdconfig -a -u 99 -t vnode -f %s" % (test_config['disks'][0])
    print(cmd)
    ret = os.system(cmd)
    if ret != 0:
        sys.exit(ret)

    temp_dir = tempfile.mkdtemp()
    cmd = "mount /dev/md99 %s" % (temp_dir)
    ret = os.system(cmd)
    if ret != 0:
        sys.exit(ret)

    cmd = "cp %s/usr/tests/*.xml %s/usr/tests/*.txt ." \
           % (temp_dir, temp_dir)
    os.system(cmd)

def cleanup():
    os.system("rm -f %s" % (sentinel_file))
    if temp_dir is not None:
        cmd = "umount %s" % (temp_dir)
        print(cmd)
        os.system(cmd)

    cmd = "mdconfig -d -u 99"
    print(cmd)
    os.system(cmd)

if __name__ == "__main__":
    atexit.register(cleanup)
    main(sys.argv)
