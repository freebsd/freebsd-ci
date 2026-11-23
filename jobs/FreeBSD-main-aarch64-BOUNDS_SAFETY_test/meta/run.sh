#!/bin/sh

METADIR=/meta
sh -ex ${METADIR}/disable-dtrace-tests.sh
sh -ex ${METADIR}/disable-zfs-tests.sh
sh -ex ${METADIR}/disable-notyet-tests.sh

# The bounds-safety hook test raises violations on purpose, so count the
# rest of the suite first and run it on its own afterwards.
K=/usr/tests/sys/kern/Kyuafile
cp ${K} ${K}.orig
sed -i '' '/"bounds_safety_test"/d' ${K}
sysctl debug.bounds_soft_trap_verbose=1 debug.bounds_soft_trap_max_pps=0
sh -ex ${METADIR}/run-kyua.sh
sysctl -n kern.bounds_soft_violations > ${METADIR}/bounds-violations.txt
dmesg | grep 'bounds-safety: soft trap' | sort | uniq -c > \
    ${METADIR}/bounds-soft-traps.txt || true
mv ${K}.orig ${K}

cd /usr/tests/sys/kern
kyua test bounds_safety_test || true
kyua report --verbose --output ${METADIR}/bounds-safety-test-report.txt
