#!/bin/sh

rm -f meta.tar
truncate -s 512M meta.tar
tar rvf meta.tar -C meta .
