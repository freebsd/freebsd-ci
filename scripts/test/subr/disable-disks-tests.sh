#!/bin/sh

if [ -f /etc/kyua/kyua.conf ]; then
	sed -i .bak -E \
		-e 's,test_suites.FreeBSD.(cam|disks),-- &,' \
		/etc/kyua/kyua.conf
fi
