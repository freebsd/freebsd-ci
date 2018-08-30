#!/bin/sh

if [ -f /usr/tests/sys/cddl/Kyuafile ]; then
	sudo sed -i .bak \
		-e 's,include("zfs/Kyuafile"),-- include("zfs/Kyuafile"),' \
		/usr/tests/sys/cddl/Kyuafile
fi
