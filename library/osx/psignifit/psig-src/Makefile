SHELL = /bin/sh

# stage 2:
# CYGFLAG, DBFLAG and OUTDIR are all specified as constants within the makefile.
# The finished target turns ends up in OUTDIR, but the .o and .d  files are still
# mixed in with the source, and are given the same names even irrespective of
# CYGFLAG and DBFLAG.

CYGFLAG = 
DBFLAG  = -g
OUTDIR  = ~/bin

CC = gcc
CFLAGS = $(CYGFLAG) $(DBFLAG)
CXX = g++
CXXFLAGS = $(CYGFLAG) $(DBFLAG)
LD = gcc $(CYGFLAG) $(DBFLAG)
LDFLAGS = 
DEPEND_FLAG = -MM  # GNU compilers support -MM, others may only support -M

csource = $(wildcard *.c)
cppsource = $(wildcard *.cpp)
objects = $(csource:.c=.o) $(cppsource:.cpp=.o)
dependencies = $(objects:.o=.d)

# to put .o, .d in separate directory: when creating $(objects),
# do an additional pattern replace on objects so that $(OBJDIR)/
# is prefixed and -$(STEM) is inserted before the .o
# $(OBJDIR) and $(STEM) must then be taken into account in the %.d rules below


.PHONY: clean gnu dos mex gnu-db mex-db dos-db

gnu : $(OUTDIR)/psignifit

# gnu, gnu-db
# win, win-db
# mex, mex-db
# targets should be able to override $(STEM), $(CYGFLAG) and $(DBFLAG) accordingly
# $(STEM) should be equal to the target name, reflecting both the target and the debug
# status - then the only thing left ambiguous is the finished filename, and that can
# easily be forced to update using a flag to make


$(OUTDIR)/psignifit : $(objects)
	$(LD) $(LDFLAGS) -o $@ $(objects)

%.d : %.c
	@ set -e; $(CC) $(DEPEND_FLAG) $(CFLAGS) $< \
	| sed 's/\($*\)\.o[ :]*/\1.o $@ : /g' > $@; \
	[ -s $@ ] || rm -f $@

%.d : %.cpp
	@ set -e; $(CXX) $(DEPEND_FLAG) $(CXXFLAGS) $< \
	| sed 's/\($*\)\.o[ :]*/\1.o $@ : /g' > $@; \
	[ -s $@ ] || rm -f $@

include $(dependencies)

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@	
%.o: %.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

clean :
	@ -rm $(objects) $(dependencies)

