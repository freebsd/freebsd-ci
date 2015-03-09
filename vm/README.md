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

2. Add something like the following in /etc/rc.conf to enable the tap devices:

```
    #####################################################
    # Create tap devices, one tap interface per BHyve VM.
    # Add the tap interfaces to bridge0
    ####################################################
    cloned_interfaces="bridge0 tap0 tap1"

    autobridge_interfaces="bridge0"
    autobridge_bridge0="tap* igb0"
```


   Each VM should have a separate tap device, all connected to the same bridge.
   If you add more VM's, remember to add another tap device to cloned_interfaces

3. Add the following to /etc/sysctl.conf on the host machine:

```
    # BHyve needs this for tap interfaces
    net.link.tap.user_open=1
    net.link.tap.up_on_open=1
```

   Refer to: http://www.freebsd.org/doc/handbook/network-bridging.html 
