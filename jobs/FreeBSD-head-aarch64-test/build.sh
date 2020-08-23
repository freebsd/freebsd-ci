#!/bin/sh

export TARGET=arm64
export TARGET_ARCH=aarch64
export USE_QEMU=1
export QEMU_ARCH="aarch64"
export QEMU_MACHINE="virt"
# XXX: U-Boot gets confused with two virtio drives.
export QEMU_DEVICES="-device virtio-blk,drive=hd0 -device ahci,id=ahci -device ide-hd,drive=hd1,bus=ahci.0"
export QEMU_EXTRA_PARAM="-bios /usr/local/share/u-boot/u-boot-qemu-arm64/u-boot.bin -cpu cortex-a57"

# XXX: Temporary, to compare performance results.
export VM_CPU_COUNT=1

export USE_TEST_SUBR="
disable-disks-tests.sh
disable-dtrace-tests.sh
disable-zfs-tests.sh
disable-notyet-tests.sh
run-kyua.sh
"

sh -x freebsd-ci/scripts/test/run-tests.sh

# Turn known test failures into xfails.
while read t; do echo xml ed -P -L -r "/testsuite/testcase[@classname=\"$t\"]/error" -v skip test-result.xml; done << END
lib.libc.string.memcmp_test.diff
lib.libexecinfo.backtrace_test.backtrace_fmt_basic
lib.msun.exponential_test.main
lib.msun.fenv_test.main
lib.msun.fma_test.main
lib.msun.invtrig_test.main
lib.msun.logarithm_test.main
lib.msun.lrint_test.main
lib.msun.nearbyint_test.main
lib.msun.next_test.main
lib.msun.rem_test.main
lib.msun.trig_test.special
libexec.tftpd.functional.dotdot_v6
libexec.tftpd.functional.s_flag_v6
libexec.tftpd.functional.wrq_dropped_data_v6
sys.capsicum.capsicum-test.main
sys.fs.fusefs.io.main
sys.kern.coredump_phnum_test.coredump_phnum
sys.kern.ptrace_test.ptrace__PT_STEP_with_signal
END
