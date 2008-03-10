#	Make Include for src/Makefile and src/Makefile.WIN32
#
# 	This Makefile has been updated from the DP toolbox to only 
#       build the DPLOW and DP executable files. These are in turn also 
#       partly modified. See dplow/pm_updated.txt. E. Svahn Apr 2001
#
#	Copyright (c) 1995-1999 University of Rostock, Germany,
#	Institute of Automatic Control. All rights reserved.
#
#	See file ``Copyright'' for terms of copyright.
#
#	Authors: S. Pawletta, A. Westphal

DPLOWMEXS	=	m2pvm.$(MEXSUFFIX) \
			persistent2.$(MEXSUFFIX) \
			putenv.$(MEXSUFFIX) \
			unsetenv.$(MEXSUFFIX) \
			selectstdin.$(MEXSUFFIX)

M2PVMOBJS	=	m2pvm.$(OBJSUFFIX) \
			m2libpvm.$(OBJSUFFIX) \
			m2libpvme.$(OBJSUFFIX) \
			pvmectrl.$(OBJSUFFIX) \
			pvmeprocctrl.$(OBJSUFFIX) \
			pvmeupk.$(OBJSUFFIX) \
			misc.$(OBJSUFFIX)

PERSISTENT2OBJS	=	persistent2.$(OBJSUFFIX) \
			misc.$(OBJSUFFIX)

DPLOWEXECS	=	pvm_start_pvmd$(EXEEXT)

DPEXECS		=	dpmatlab$(EXEEXT)

install:		$(INSTALL_DPTB)

install-implib:		meximports.lib

install-dplowmexs:	$(DPLOWMEXS)
	$(CP) m2pvm.$(MEXSUFFIX)	..$(DS)dplow$(DS)M$(PM_VER)
	$(CP) persistent2.$(MEXSUFFIX)	..$(DS)dplow$(DS)M$(PM_VER)
	$(CP) putenv.$(MEXSUFFIX)	..$(DS)dplow$(DS)M$(PM_VER)
	$(CP) unsetenv.$(MEXSUFFIX)	..$(DS)dplow$(DS)M$(PM_VER)
	$(CP) selectstdin.$(MEXSUFFIX)	..$(DS)dplow$(DS)M$(PM_VER)

install-dplowexecs:	$(DPLOWEXECS)
	- mkdir				..$(DS)bin$(DS)$(PVM_ARCH)
	$(CP) $(DPLOWEXECS)		..$(DS)bin$(DS)$(PVM_ARCH)

install-dpexecs:	$(DPEXECS)
	- mkdir				..$(DS)bin$(DS)$(PVM_ARCH)
	$(CP) $(DPEXECS)		..$(DS)bin$(DS)$(PVM_ARCH)

clean:
	$(RM) *.$(OBJSUFFIX)
	$(RM) *.lib
	$(RM) *.exp
	$(RM) *.$(MEXSUFFIX)
	$(RM) $(DPLOWEXECS)
	$(RM) $(DPEXECS)

tidy:
	$(RM) *.$(OBJSUFFIX)
	$(RM) *.lib
	$(RM) *.exp
	$(RM) *.$(MEXSUFFIX)
	$(RM) ..$(DS)dplow$(DS)M$(PM_VER)$(DS)*.$(MEXSUFFIX)
	$(RM) ..$(DS)dpmm$(DS)M$(PM_VER)$(DS)*.$(MEXSUFFIX)
	$(RM) $(DPLOWEXECS)
	$(RM) ..$(DS)bin$(DS)$(PVM_ARCH)$(DS)$(DPLOWEXECS)
	$(RM) $(DPEXECS)
	$(RM) ..$(DS)bin$(DS)$(PVM_ARCH)$(DS)$(DPEXECS)


meximports.lib:	$(MEXDEF)
	lib -nologo -def:$(MEXDEF) -out:meximports.lib -machine:IX86


m2pvm.$(MEXSUFFIX):		$(M2PVMOBJS) mexversion.$(OBJSUFFIX)
	$(LD) $(LDMEXFLAGS) $(LDOUT)m2pvm.$(MEXSUFFIX) \
	      $(M2PVMOBJS) mexversion.$(OBJSUFFIX) $(LIBSMEX)

persistent2.$(MEXSUFFIX):	$(PERSISTENT2OBJS) mexversion.$(OBJSUFFIX) 
	$(LD) $(LDMEXFLAGS) $(LDOUT)persistent2.$(MEXSUFFIX) \
	      $(PERSISTENT2OBJS) mexversion.$(OBJSUFFIX) $(LIBSMEX)

putenv.$(MEXSUFFIX):		putenv.$(OBJSUFFIX) mexversion.$(OBJSUFFIX)
	$(LD) $(LDMEXFLAGS) $(LDOUT)putenv.$(MEXSUFFIX) \
	      putenv.$(OBJSUFFIX) mexversion.$(OBJSUFFIX) $(LIBSMEX) 

unsetenv.$(MEXSUFFIX):		unsetenv.$(OBJSUFFIX) mexversion.$(OBJSUFFIX)
	$(LD) $(LDMEXFLAGS) $(LDOUT)unsetenv.$(MEXSUFFIX) \
	      unsetenv.$(OBJSUFFIX) mexversion.$(OBJSUFFIX) $(LIBSMEX)

selectstdin.$(MEXSUFFIX):	selectstdin.$(OBJSUFFIX) mexversion.$(OBJSUFFIX)
	$(LD) $(LDMEXFLAGS) $(LDOUT)selectstdin.$(MEXSUFFIX) \
	      selectstdin.$(OBJSUFFIX) mexversion.$(OBJSUFFIX) $(LIBSMEX)

pvm_start_pvmd$(EXEEXT):	pvm_start_pvmd.$(OBJSUFFIX)
	$(CC) $(CCOUT)pvm_start_pvmd$(EXEEXT) \
	      pvm_start_pvmd.$(OBJSUFFIX) $(LIBS)

dpmatlab$(EXEEXT):		dpmatlab.$(OBJSUFFIX)
	$(CC) $(CCOUT)dpmatlab$(EXEEXT) \
	      dpmatlab.$(OBJSUFFIX) $(LIBS)

mexversion.$(OBJSUFFIX):	$(MEXVERSRC)
	$(CC) $(CFLAGS) -c $(MEXVERSRC)

m2pvm.$(OBJSUFFIX):		m2pvm.c
	$(CC) $(CFLAGS) -c m2pvm.c

persistent2.$(OBJSUFFIX):	persistent2.c
	$(CC) $(CFLAGS) -c persistent2.c

putenv.$(OBJSUFFIX):		putenv.c
	$(CC) $(CFLAGS) -c putenv.c

unsetenv.$(OBJSUFFIX):		unsetenv.c
	$(CC) $(CFLAGS) -c unsetenv.c

selectstdin.$(OBJSUFFIX):	selectstdin.c
	$(CC) $(CFLAGS) -c selectstdin.c

pvm_start_pvmd.$(OBJSUFFIX):	pvm_start_pvmd.c
	$(CC) $(CFLAGS) -c pvm_start_pvmd.c

dpmatlab.$(OBJSUFFIX):		dpmatlab.c
	$(CC) $(CFLAGS) -c dpmatlab.c

m2libpvm.$(OBJSUFFIX):		m2libpvm.c
	$(CC) $(CFLAGS) -c m2libpvm.c

m2libpvme.$(OBJSUFFIX):		m2libpvme.c
	$(CC) $(CFLAGS) -c m2libpvme.c

pvmectrl.$(OBJSUFFIX):		pvmectrl.c
	$(CC) $(CFLAGS) -c pvmectrl.c

pvmeprocctrl.$(OBJSUFFIX):	pvmeprocctrl.c
	$(CC) $(CFLAGS) -c pvmeprocctrl.c

pvmeupk.$(OBJSUFFIX):		pvmeupk.c
	$(CC) $(CFLAGS) -c pvmeupk.c

misc.$(OBJSUFFIX):		misc.c
	$(CC) $(CFLAGS) -c misc.c


.SUFFIXES: .$(MEXSUFFIX)

include ../conf/rules.mk


# .h deps
m2pvm.$(OBJSUFFIX):	m2libpvm.h m2libpvme.h misc.h matrix_m4_m5.h
persistent2.$(OBJSUFFIX):	misc.h mex_m4_m5.h
putenv.$(OBJSUFFIX):	mex_m4_m5.h
unsetenv.$(OBJSUFFIX):	mex_m4_m5.h
selectstdin.$(OBJSUFFIX):	mex_m4_m5.h
m2libpvm.$(OBJSUFFIX):	m2libpvm.h misc.h mex_m4_m5.h matrix_m4_m5.h
m2libpvme.$(OBJSUFFIX):	m2libpvme.h pvme.h misc.h
pvmectrl.$(OBJSUFFIX):	pvme.h misc.h
pvmeprocctrl.$(OBJSUFFIX):	pvme.h
pvmeupk.$(OBJSUFFIX):	pvme.h
misc.$(OBJSUFFIX):		misc.h

