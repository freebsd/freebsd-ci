#!/bin/sh

truncate -s 128M meta.tar
tar rvf meta.tar meta
