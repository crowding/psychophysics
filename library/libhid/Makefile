#############################################################################
#	
#	Makefile for building:
#
#		libmcchid.so:        Library for USB series
#		test-usb1208LS:   Program to test USB-1208LS module
#		test-usb1024LS:   Program to test USB-1024LS module
#		test-usb1208FS:   Program to test USB-1208FS module
#		test-usb1608FS:   Program to test USB-1208FS module
#		test-usb-dio96H:  Program to test USB-1096HFS, USB-DIO96H, and USB-DIO96H/50
#		test-usb1616FS:   Program to test USB-1616FS module
#               test-usb3100:     Program to test USB-3100 modules
#		test-usb-tc:      Program to test USB-TC module
#		test-usb-temp:    Program to test USB-TEMP module
#               test-usb5201:     Program to test USB-5201 module
#		test-minilab1008: Program to test miniLAB 1008 module
#               test-usb-ssr:     Program to test USB-SSR24 and SSR08 modules
#               test-usb-pdiso8:  Program to test USB-PDISO8
#               test-usb500:      Program to test USB-501 and USB-502
#               test-usb-erb      Program to test USB-ERB08 and USB-ERB24
#               test-usb4300      Program to test USB-430X
#               test-usb-dio24    Program to test USB-DIO24 and USB-DIO24H
#
#               Copyright (C) February 5, 2005
#               Written by:  Warren J. Jasper
#                            North Carolina State Univerisity
#
#
# This program, libmcchid.so, is free software; you can redistribute it
# and/or modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of the
# License, or (at your option) any later version, provided that this
# copyright notice is preserved on all copies.
#
# ANY RIGHTS GRANTED HEREUNDER ARE GRANTED WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, AND FURTHER,
# THERE SHALL BE NO WARRANTY AS TO CONFORMITY WITH ANY USER MANUALS OR
# OTHER LITERATURE PROVIDED WITH SOFTWARE OR THAM MY BE ISSUED FROM TIME
# TO TIME. IT IS PROVIDED SOLELY "AS IS".
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
###########################################################################

#  Current Version of the driver
VERSION=1.21

#SRCS    = pmd.c usb-1208LS.c usb-1608FS.c usb-1208FS.c usb-1024LS.c usb-tc.c usb-temp.c usb-5201.c usb-dio96H.c usb-1616FS.c minilab-1008.c usb-ssr.c usb-3100.c usb-pdiso8.c usb-erb.c usb-4303.c usb-dio24.c
SRCS    = pmd.c usb-1208FS.c 
#HEADERS = pmd.h usb-1208LS.h usb-1608FS.h usb-1208FS.h usb-1024LS.h usb-tc.h usb-temp.h usb-5201.h usb-dio96H.h usb-1616FS.h minilab-1008.h usb-ssr.h usb-500.h usb-3100.h usb-pdiso8.h usb-erb.h usb-4303.h usb-dio24.h
HEADERS = pmd.h usb-1208FS.h 
OBJS = $(SRCS:.c=.o)   # same list as SRCS with extension changed
CC=gcc
CFLAGS= -g -Wall -I/sw/include
#CFLAGS= -g -Wall -I/sw/include -static
#TARGETS=libmcchid.so libmcchid.a test-usb1208LS test-usb1608FS test-usb1208FS test-usb1024LS test-usb-tc test-usb-temp test-usb5201 test-usb-dio96H test-usb1616FS test-minilab1008 test-usb-ssr test-usb500 test-usb3100 test-usb-pdiso8 test-usb-erb test-usb4300 test-usb-dio24
#TARGETS=libmcchid.so libmcchid.a test-usb1208FS 
TARGETS=libmcchid.a test-usb1208FS 
ID=MCCLIBHID
DIST_NAME=$(ID).$(VERSION).tgz
DIST_FILES={Makefile,usb-1208LS.h,usb-1208LS.c,usb-1608FS.h,usb-1608FS.c,usb-tc.h,usb-tc.c,usb-temp.h,usb-temp.c,usb-5201.c,usb-5201.h,pmd.h,pmd.c,usb-1208FS.h,usb-1208FS.c,usb-1024LS.h,usb-1024LS.c,usb-dio96H.h,usb-dio96H.c,usb-1616FS.h,usb-1616FS.c,usb-3100.h,usb-3100.c,minilab-1008.h,minilab-1008.c,usb-ssr.h,usb-ssr.c,usb-pdiso8.h,usb-pdiso8.c,usb-500.h,usb-erb.h,usb-erb.c,usb-4303.h,usb-4303.c,usb-dio24.h,usb-dio24.c,test-usb1208LS.c,test-usb1608FS.c,test-usb1208FS.c,test-usb1024LS.c,test-usb-tc.c,test-usb-temp.c,test-usb5201.c,test-usb-dio96H.c,test-usb1616FS.c,test-minilab1008.c,test-usb-ssr.c,test-usb500.c,test-usb3100.c,test-usb-pdiso8.c,test-usb-erb.c,test-usb4300.c,test-usb-dio24.c}
###### RULES
all: $(TARGETS)

%.d: %.c
	set -e; $(CC) -I. -M $(CPPFLAGS) $< \
	| sed 's/\($*\)\.o[ :]*/\1.o $@ : /g' > $@; \
	[ -s $@ ] || rm -f $@
ifneq ($(MAKECMDGOALS),clean)
include $(SRCS:.c=.d)
endif

libmcchid.so: $(OBJS)
	$(CC) -shared -Wall $(OBJS) -o $@

libmcchid.a: $(OBJS)
	ar -r libmcchid.a $(OBJS)
	ranlib libmcchid.a

test-usb1208LS:	test-usb1208LS.c libmcchid.a
	$(CC) $(CFLAGS) -I. -o $@  $@.c -lmcchid -L. -lm -L/usr/local/lib -L/sw/lib -lhid -lusb 

test-usb1024LS:	test-usb1024LS.c libmcchid.a
	$(CC) $(CFLAGS) -I. -o $@  $@.c -lmcchid -L. -lm -L/usr/local/lib -L/sw/lib -lhid -lusb 

test-usb1208FS:	test-usb1208FS.c libmcchid.a
	$(CC) $(CFLAGS) -I. -o $@  $@.c -lmcchid -L. -lm -L/usr/local/lib -L/sw/lib -lhid -lusb 

test-usb1608FS:	test-usb1608FS.c libmcchid.a
	$(CC) $(CFLAGS) -I. -o $@  $@.c -lmcchid -L. -lm -L/usr/local/lib -L/sw/lib -lhid -lusb 

test-usb3100:  test-usb3100.c libmcchid.a
	$(CC) $(CFLAGS) -I. -o $@  $@.c -lmcchid -L. -lm -L/usr/local/lib -L/sw/lib -lhid -lusb 

test-usb-tc: test-usb-tc.c libmcchid.a
	$(CC) $(CFLAGS) -I. -o $@  $@.c -lmcchid -L. -lm -L/usr/local/lib -L/sw/lib -lhid -lusb 

test-usb-temp: test-usb-temp.c libmcchid.a
	$(CC) $(CFLAGS) -I. -o $@  $@.c -lmcchid -L. -lm -L/usr/local/lib -L/sw/lib -lhid -lusb 

test-usb5201: test-usb5201.c libmcchid.a
	$(CC) $(CFLAGS) -I. -o $@  $@.c -lmcchid -L. -lm -L/usr/local/lib -L/sw/lib -lhid -lusb 

test-usb-dio96H: test-usb-dio96H.c libmcchid.a
	$(CC) $(CFLAGS) -I. -o $@  $@.c -lmcchid -L. -lm -L/usr/local/lib -L/sw/lib -lhid -lusb 

test-usb1616FS: test-usb1616FS.c libmcchid.a
	$(CC) $(CFLAGS) -I. -o $@  $@.c -lmcchid -L. -lm -L/usr/local/lib -L/sw/lib -lhid -lusb 

test-minilab1008: test-minilab1008.c libmcchid.a
	$(CC) $(CFLAGS) -I. -o $@  $@.c -lmcchid -L. -lm -L/usr/local/lib -L/sw/lib -lhid -lusb 

test-usb-ssr: test-usb-ssr.c libmcchid.a
	$(CC) $(CFLAGS) -I. -o $@  $@.c -lmcchid -L. -lm -L/usr/local/lib -L/sw/lib -lhid -lusb 

test-usb-pdiso8: test-usb-pdiso8.c libmcchid.a
	$(CC) $(CFLAGS) -I. -o $@  $@.c -lmcchid -L. -lm -L/usr/local/lib -L/sw/lib -lhid -lusb 

test-usb500:  test-usb500.c
	$(CC) $(CFLAGS) -o $@ $@.c -lm -lusb

test-usb-erb:  test-usb-erb.c libmcchid.a
	$(CC) $(CFLAGS) -I. -o $@  $@.c -lmcchid -L. -lm -L/usr/local/lib -L/sw/lib -lhid -lusb 

test-usb4300: test-usb4300.c libmcchid.a
	$(CC) $(CFLAGS) -I. -o $@  $@.c -lmcchid -L. -lm -L/usr/local/lib -L/sw/lib -lhid -lusb 

test-usb-dio24: test-usb-dio24.c libmcchid.a
	$(CC) $(CFLAGS) -I. -o $@  $@.c -lmcchid -L. -lm -L/usr/local/lib -L/sw/lib -lhid -lusb 

clean:
	rm -rf *.d *.o *~ *.a *.so $(TARGETS)

dist:	
	make clean
	cd ..; tar -zcvf $(DIST_NAME) libhid/$(DIST_FILES);

install:
	-install -d /usr/local/lib
	-install -c ./libmcchid.a libmcchid.so /usr/local/lib
	-/bin/ln -s /usr/local/lib/libmcchid.so /usr/lib/libmcchid.so
	-/bin/ln -s /usr/local/lib/libmcchid.a /usr/lib/libmcchid.a

uninstall:
	-rm -f /usr/local/lib/libmcchid*
	-rm -f /usr/lib/libmcchid*
