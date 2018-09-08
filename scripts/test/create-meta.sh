#!/bin/sh

rm -f meta.tar
truncate -s 128M meta.tar
tar rvf meta.tar -C meta .
