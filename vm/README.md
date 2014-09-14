# BHyve startup scripts

These scripts are used to start BSD Hypervisor (BHyve) VM's on boot.

## Setup

1. Copy or symlink the bhyvevm script to /usr/local/etc/rc.d/bhyvevm

2. For each VM that is created, create a separate vm.conf file.
   The conf file has parameters that are used when starting the VM.

3. For each VM that is created, edit the bhyvevm script and add the VM to the bhyvevm_start()
   and bhyvevm_stop() functions.

## /etc/rc.conf

1. Put something like the following in /etc/rc.conf

```
    #####################################################
    # List of bhyve vms
    #####################################################
    bhyvevm_enable="YES"
    bhyvevm_list="jenkins10 jenkins9"
    bhyvevm_jenkins10_conf="/vm/freebsd-ci/vm/10.0/jenkins10.conf"
    bhyvevm_jenkins9_conf="/vm/freebsd-ci/vm/9.2/jenkins9.conf"
```
