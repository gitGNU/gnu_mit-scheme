@echo off
rem MIT Scheme microcode configuration script for OS/2
rem
rem Copyright (c) 1994, 1995, 2000 Massachusetts Institute of Technology
rem
rem $Id: config.cmd,v 1.3.2.1 2000/11/27 05:58:01 cph Exp $
rem
copy cmpintmd\i386.h cmpintmd.h
copy cmpauxmd\i386.m4 cmpauxmd.m4
copy os2utl\makefile .
copy os2utl\config.h .
copy cmpauxmd\asmcvt.c .
echo ***** Read and edit the makefile! *****
