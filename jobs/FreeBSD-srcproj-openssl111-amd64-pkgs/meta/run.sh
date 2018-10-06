#!/bin/sh

METADIR=/meta

zpool create tank /dev/ada2
zfs set atime=off tank
zfs set compression=lz4 tank
zfs create tank/ports

svnlite co -q svn://svn.freebsd.org/ports/head /tank/ports
