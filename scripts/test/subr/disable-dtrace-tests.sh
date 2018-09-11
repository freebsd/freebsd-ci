#!/bin/sh

if [ -f /usr/tests/cddl/usr.sbin/dtrace/Kyuafile ]; then
	mv /usr/tests/cddl/usr.sbin/dtrace/Kyuafile \
		/usr/tests/cddl/usr.sbin/dtrace/Kyuafile.bak
fi
