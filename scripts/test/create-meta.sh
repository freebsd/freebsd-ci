#!/bin/sh

truncate -s 1M meta.tar
ls -al meta.tar
tar rvf meta.tar meta
ls -al meta.tar
