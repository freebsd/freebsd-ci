# FreeBSD Continuous Integration Salt Automation

This repo contains salt configuration for managing the CI cluster.

## Installation
See: http://docs.saltstack.com/en/latest/topics/installation/freebsd.html

 * pkg install -y py27-salt #on master and all minions
 * Use config files (master, master.d/) from this repo #not samples
 * Ensure a salt CNAME exists for salt master node
 * Start salt_master service and salt_minion services
 * use salt-key (-L: list, -A: Accept all) node memberships if appropriate
 * Test with: salt '*' test.ping

## Usage

Report OS version

```
salt '*' grains.item os osrelease osarch
```

Audit packages

```
salt '*' pkg.audit
```

Install a package on jenkins node group

```
salt -N jenkins pkg.install sudo
```

Run pkg upgrade, on bhyve VMs

```
salt -G 'virtual:bhyve' pkg.upgrade
```
