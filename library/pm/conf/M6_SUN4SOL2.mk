#	make include for Matlab 6 on Solaris 2
#
#       Based on the file M5.SUN4SOL2.mk from the DP toolbox.
#       Modified by E.Svahn for parallel Matlab toolbox, Nov 2000      
#
#	Copyright (c) 1998-1999 University of Rostock, Germany, 
#	Institute of Automatic Control. All rights reserved.
#
#	See file ``COPYRIGHT'' for terms of copyright.
#
#	Author: S. Pawletta

SHELL		= /bin/sh
CC		= gcc
LD		= /usr/ccs/bin/ld

CFLAGS		= -O -DNOUNSETENV -DTIMEOUT=180\
		  -DNDEBUG -DMATLAB_MEX_FILE -DTMP_LOC='"$(TMP_LOC)"'\
		  -I$(M6_ROOT)/extern/include \
		  -I$(PVM_ROOT)/include

LDMEXFLAGS	= -G -M $(M6_ROOT)/extern/lib/sol2/mexFunction.map

LIBS		= $(PVM_ROOT)/lib/$(PVM_ARCH)/libpvm3.a -lsocket -lnsl

LIBSMEX		= $(LIBS)


MEXVERSRC 	= $(M6_ROOT)/extern/src/mexversion.c
MEXSUFFIX	= mexsol


OBJSUFFIX	= o
EXEEXT		=
CCOUT		= -o 
LDOUT		= -o 
DS		= /
CS		= ;
CP		= cp
RM		= rm -f

INSTALL_DPTB	= install-dplowmexs \
		  install-dpexecs 

