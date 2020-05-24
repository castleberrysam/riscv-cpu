#!/bin/sh

SRCS=$(find src -type f -name \*.v)
yosys -p 'hierarchy -check -top top; proc; flatten; opt -full; ltp -noff; stat' $SRCS
