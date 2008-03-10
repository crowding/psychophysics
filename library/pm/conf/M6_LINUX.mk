#	make include for Matlab 6 on Linux
#
#       Based on the file M5.LINUX.mk from the DP toolbox.
#       Modified by E.Svahn for parallel Matlab toolbox, Nov 2000      
#
#	Copyright (c) 1995-1999 University of Rostock, Germany, 
#	Institute of Automatic Control. All rights reserved.
#
#	See file ``COPYRIGHT'' for terms of copyright.
#
#	Author: S. Pawletta

SHELL		= /bin/sh
CC		= gcc
LD		= gcc

CFLAGS		= -O \
		  -DNDEBUG -DMATLAB_MEX_FILE -DTMP_LOC='"$(TMP_LOC)"'\
		  -I$(M6_ROOT)/extern/include \
		  -I$(PVM_ROOT)/include

LDMEXFLAGS	= -L$(M6_ROOT)/bin/glnx86 -shared

LIBS		= $(PVM_ROOT)/lib/$(PVM_ARCH)/libpvm3.a 

LIBSMEX		= -lmx $(LIBS)


MEXVERSRC 	= $(M6_ROOT)/extern/src/mexversion.c
MEXSUFFIX	= mexglx


OBJSUFFIX	= o
EXEEXT		=
CCOUT		= -o 
LDOUT		= -o 
DS		= /
CS		= ;
CP		= cp
RM		= rm -f

INSTALL_DPTB	= install-dplowmexs \
		  install-dpexecs \

