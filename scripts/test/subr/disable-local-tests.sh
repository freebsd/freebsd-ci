#!/bin/sh

F=/usr/tests/local/Kyuafile
if [ -f ${F} ]; then
	mv ${F} ${F}.bak
fi
