#!/bin/sh

F=/usr/tests/lib/libcasper/services/cap_dns/Kyuafile
if [ -f ${F} ]; then
	sed -i .bak \
		-e 's/tap_test_program{name="dns_test", }/-- tap_test_program{name="dns_test", }/' \
		${F}
fi

F=/usr/tests/sys/netinet6/Kyuafile
if [ "$(uname -m)" = "i386" ] && [ -f ${F} ]; then
	sed -i .bak \
		-e 's,include("frag6/Kyuafile"),-- include("frag6/Kyuafile"),' \
		${F}
fi

F=/usr/local/tests/kyua/utils/signals/Kyuafile
if [ -f ${F} ]; then
	sed -i .bak \
		-e 's,atf_test_program{name="timer_test"},-- atf_test_program{name="timer_test"},' \
		${F}
fi
