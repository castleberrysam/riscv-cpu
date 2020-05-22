#!/bin/sh

SRCS=$(find src -type f -name \*.v -not -name tb_\*)
yosys -p 'proc; hierarchy -check -top top; flatten; opt -full; shell' $SRCS
