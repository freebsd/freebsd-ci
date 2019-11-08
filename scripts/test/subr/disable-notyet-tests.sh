#!/bin/sh

F=/usr/tests/lib/libcasper/services/cap_dns/Kyuafile
if [ -f ${F} ]; then
	sed -i .bak \
		-e 's/tap_test_program{name="dns_test", }/-- tap_test_program{name="dns_test", }/' \
		${F}
fi

F=/usr/local/tests/kyua/utils/signals/Kyuafile
if [ -f ${F} ]; then
	sed -i .bak \
		-e 's,atf_test_program{name="timer_test"},-- atf_test_program{name="timer_test"},' \
		${F}
fi
