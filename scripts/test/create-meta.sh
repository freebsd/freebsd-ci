#!/bin/sh

rm -f meta.tar
truncate -s 256M meta.tar
tar rvf meta.tar -C meta .
