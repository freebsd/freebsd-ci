# FreeBSD Continuous Integration Salt Automation

This repo contains salt configuration for managing the CI cluster.

## Installation
See: http://docs.saltstack.com/en/latest/topics/installation/freebsd.html

 * pkg install -y sysutils/py-salt #on master and all minions
 * Use config files (master, master.d/, minion) from this repo #not samples
 * In the minion file, make sure master: is defined and refers to the
   DNS name of the master node.  If this is not defined, each minion will try to connect
   to a master with DNS name "salt".
 * Start salt_master service and salt_minion services
 * Use salt-key (-L: list, -A: Accept all) node memberships if appropriate
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

Launch a background freebsd-update job. We use cron as fetch does not allow
non-interactive use. Here is how to interrogate background jobs

```
# salt --async 'jenkins-10.*' cmd.run "freebsd-update cron install"
Executed command with job ID: 20150108050304504294
# salt-run jobs.active
# salt-run jobs.list_job 20150108050304504294
```

