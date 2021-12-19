#!/bin/sh

F=/usr/tests/lib/libcasper/services/cap_dns/Kyuafile
if [ -f ${F} ]; then
	sed -i .bak \
		-e 's/tap_test_program{name="dns_test", }/-- tap_test_program{name="dns_test", }/' \
		${F}
fi

F=/usr/tests/lib/libcasper/services/cap_net/Kyuafile
if [ -f ${F} ]; then
	sed -i .bak \
		-e 's/atf_test_program{name="net_test", }/-- atf_test_program{name="net_test", }/' \
		${F}
fi

F=/usr/local/tests/kyua/utils/signals/Kyuafile
if [ -f ${F} ]; then
	sed -i .bak \
		-e 's,atf_test_program{name="timer_test"},-- atf_test_program{name="timer_test"},' \
		${F}
fi

F=/usr/local/tests/kyua/integration/cmd_about_test
if [ -f ${F} ]; then
	sed -i .bak \
		-e 's,atf_add_test_case topic__authors__installed,#atf_add_test_case topic__authors__installed,' \
		${F}
	rm -f ${F}.bak
fi

F=/usr/tests/sys/netmap/Kyuafile
if [ -f ${F} ]; then
	sed -i .bak \
		-e 's,plain_test_program{name="ctrl-api-test",-- plain_test_program{name="ctrl-api-test",' \
		${F}
fi
