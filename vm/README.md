# BHyve startup scripts

These scripts are used to start BSD Hypervisor (BHyve) VM's on boot.

## Setup

1. Copy or symlink the bhyvevm script to /usr/local/etc/rc.d/bhyvevm

2. For each VM that is created, create a separate vm.conf file.
   The conf file has parameters that are used when starting the VM.

3. For each VM that is created, edit the bhyvevm script and add the VM to the bhyvevm_start()
   and bhyvevm_stop() functions.

