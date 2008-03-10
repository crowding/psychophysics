#	make include for Matlab 6 on AIX46K
#
#       Based on the file M5.AIX46K.mk from the DP toolbox.
#       Modified by E.Svahn for parallel Matlab toolbox, March 2001      
#
#	Copyright (c) 1998-1999 University of Rostock, Germany, 
#	Institute of Automatic Control. All rights reserved.
#
#	See file ``COPYRIGHT'' for terms of copyright.
#
#	Author: S. Pawletta

SHELL		= /bin/sh
CC		= cc
LD		= cc

CFLAGS		= -qlanglvl=ansi\
		  -DIBM_RS -DAIX46K -DNOUNSETENV -DTIMEOUT=180\
		  -DMATLAB_MEX_FILE -DTMP_LOC='"$(TMP_LOC)"'\
		  -I$(M6_ROOT)/extern/include\
		  -I$(PVM_ROOT)/include

LDMEXFLAGS      = -s -bE:$(M6_ROOT)/extern/lib/ibm_rs/mexFunction.map\
		  -bM:SRE -e mexFunction

LIBS		= $(PVM_ROOT)/lib/$(PVM_ARCH)/libpvm3.a

LIBSMEX		= $(LIBS) -L$(M6_ROOT)/bin/ibm_rs -lmx -lmex -lmatlbmx -lm -lmat


MEXVERSRC 	= $(M6_ROOT)/extern/src/mexversion.c
MEXSUFFIX	= mexrs6


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


