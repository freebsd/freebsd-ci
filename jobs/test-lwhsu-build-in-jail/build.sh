#!/bin/sh

sudo rm -fr work
mkdir -p work
cd work

fetch http://artifact.ci.freebsd.org/snapshot/head/r303605/amd64/amd64/base.txz
fetch http://artifact.ci.freebsd.org/snapshot/head/r303605/amd64/amd64/kernel.txz

mkdir -p ufs
cd ufs
sudo tar zxvf ../base.txz
sudo tar zxvf ../kernel.txz
cd -

sudo makefs -d 6144 -t ffs -f 200000 -s 2g -o version=2,bsize=32768,fsize=4096,label=ROOT ufs.img ufs
mkimg -s gpt -b ufs/boot/pmbr -p freebsd-boot:=ufs/boot/gptboot -p freebsd-swap::1G -p freebsd-ufs:=ufs.img -o disc.img
xz disc.img
