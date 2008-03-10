#
# gccopts.sh   Shell script for configuring MEX-file creation script,
#               mex.
#
# usage:        Do not call this file directly; it is sourced by the
#               mex shell script.  Modify only if you don't like the
#               defaults after running mex.  No spaces are allowed
#               around the '=' in the variable assignment.
#
#               Note: only the gcc side of this script was tested.
#               The FORTRAN variables are lifted directly from
#               mexopts.sh; use that file for compiling FORTRAN
#               MEX-files.
#
# Copyright (c) 1992-95 by The MathWorks, Inc.
# $Revision: 1.8 $  $Date: 1997/03/14 19:07:51 $
#----------------------------------------------------------------------------
#
    case "$Arch" in
        Undetermined)
#----------------------------------------------------------------------------
# Change this line if you need to specify the location of the MATLAB
# root directory.  The cmex script needs to know where to find utility
# routines so that it can determine the architecture; therefore, this
# assignment needs to be done while the architecture is still
# undetermined.
#----------------------------------------------------------------------------
            MATLAB="$MATLAB"
#
# Determine the location of the GCC libraries
#
	    GCC_LIBDIR=`gcc -v 2>&1 | awk '/.*Reading specs.*/ {print substr($4,0,length($4)-6)}'`
            ;;
        alpha)   # gcc version 2.7.2
#----------------------------------------------------------------------------
            CC='gcc'
            CFLAGS='-ansi'
            CLIBS="-L$GCC_LIBDIR -lgcc -leng -lmx"
            COPTIMFLAGS='-O -DNDEBUG'
            CDEBUGFLAGS='-g'
#
            FC='f77'
            FFLAGS='-shared'
            FLIBS='-lUfor -lfor -lFutil'
            FOPTIMFLAGS='-O'
            FDEBUGFLAGS='-g'
#
            LD='ld'
            LDFLAGS="-expect_unresolved '*' -shared -hidden -exported_symbol $ENTRYPOINT -exported_symbol mexVersion"
            LDOPTIMFLAGS=''
            LDDEBUGFLAGS=''
#----------------------------------------------------------------------------
            ;;
        hp700)   # gcc version 2.7.2
# Note: The GNU assembler does not fully support PIC.  From the Info
# documentation:
#
#     The GNU assembler does not fully support PIC.  Currently, you must
#     use some other assembler in order for PIC to work.  We would
#     welcome volunteers to upgrade GAS to handle this; the first part
#     of the job is to figure out what the assembler must do differently.
#
# PIC is necessary for building shared libraries.  Therefore, we need to
# use the HP assembler.
#----------------------------------------------------------------------------
            CC='gcc'
            CFLAGS='-ansi -fPIC -mpa-risc-1-0 -D_HPUX_SOURCE -B/usr/ccs/bin/ -mno-gas'
            CLIBS="-L$GCC_LIBDIR -lgcc"
            COPTIMFLAGS='-O -DNDEBUG'
            CDEBUGFLAGS='-g'
#
            FC='f77'
            FFLAGS='+z'
            FLIBS=''
            FOPTIMFLAGS='-O'
            FDEBUGFLAGS='-g'
#
            LD='ld'
            LDFLAGS="-b +e $ENTRYPOINT +e mexVersion"
            LDOPTIMFLAGS=''
            LDDEBUGFLAGS=''
#----------------------------------------------------------------------------
            ;;
        ibm_rs)   # gcc version 2.7.2
#----------------------------------------------------------------------------
            CC='gcc'
            CFLAGS='-ansi'
            CLIBS='-lm'
            COPTIMFLAGS='-O -DNDEBUG'
            CDEBUGFLAGS='-g'
#
            FC='f77'
            FFLAGS=''
            FLIBS="$MATLAB/extern/lib/ibm_rs/fmex1.o -lm"
            FOPTIMFLAGS='-O'
            FDEBUGFLAGS='-g'
#
            LD='gcc'
            LDFLAGS="-shared -B/usr/bin/ -Wl,-e$ENTRYPOINT,-bM:SRE,-bI:$MATLAB/extern/lib/ibm_rs/exp.ibm_rs,-bE:$MATLAB/extern/lib/ibm_rs/$MAPFILE"
            LDOPTIMFLAGS='-Wl,-s'
            LDDEBUGFLAGS=''
#----------------------------------------------------------------------------
            ;;
        lnx86)   # gcc version 2.7.2
#----------------------------------------------------------------------------
            CC='g++'
            CFLAGS='-ansi'
            CLIBS=''
            COPTIMFLAGS='-O -DNDEBUG'
            CDEBUGFLAGS='-g'
#
            FC='f77'
            FFLAGS=''
            FLIBS=''
            FOPTIMFLAGS='-O'
            FDEBUGFLAGS='-g'
#
            LD='g++'
            LDFLAGS='-shared -rdynamic'
            LDOPTIMFLAGS=''
            LDDEBUGFLAGS=''
#----------------------------------------------------------------------------
            ;;
        sgi)   # gcc version 2.6.0
#----------------------------------------------------------------------------
            CC='gcc'
            CFLAGS=''
            CLIBS="-L$GCC_LIBDIR -lgcc"
            COPTIMFLAGS='-O -DNDEBUG'
            CDEBUGFLAGS='-g'
#
            FC='f77'
            FFLAGS=''
            FLIBS=''
            FOPTIMFLAGS='-O'
            FDEBUGFLAGS='-g'
#
            LD='ld'
            LDFLAGS="-shared -U -Bsymbolic -exported_symbol $ENTRYPOINT -exported_symbol mexVersion"
            LDOPTIMFLAGS=''
            LDDEBUGFLAGS=''
            ;;
#----------------------------------------------------------------------------
        sgi64)   # gcc version 2.6.0
# R8000 only: The default action of mex is to generate full MIPS IV
#             (R8000) instruction set.
#----------------------------------------------------------------------------
            CC='gcc'
            CFLAGS=''
            CLIBS="-L$GCC_LIBDIR -lgcc"
            COPTIMFLAGS='-O -DNDEBUG'
            CDEBUGFLAGS='-g'
#
            FC='f77'
            FFLAGS=''
            FLIBS=''
            FOPTIMFLAGS='-O'
            FDEBUGFLAGS='-g'
#
            LD='ld'
            LDFLAGS="-mips4 -64 -shared -U -Bsymbolic -exported_symbol $ENTRYPOINT -exported_symbol mexVersion"
            LDOPTIMFLAGS=''
            LDDEBUGFLAGS=''
            ;;
#----------------------------------------------------------------------------
        sol2)   # gcc version 2.6.3
#----------------------------------------------------------------------------
            CC='gcc'
#           CFLAGS= '-ansi -fPIC'
	    CFLAGS='-DNOUNSETENV -I$M5_ROOT/extern/include -I$PVM_ROOT/include'
            CLIBS="-L$GCC_LIBDIR -lgcc -leng $PVM_ROOT/lib/$PVM_ARCH/libpvm3.a -lsocket -lnsl"
            COPTIMFLAGS='-O -DNDEBUG'
            CDEBUGFLAGS='-g'
#
            FC='f77'
            FFLAGS='-G'
            FLIBS=''
            FOPTIMFLAGS='-O'
            FDEBUGFLAGS='-g'
#
            LD='/usr/ccs/bin/ld'
            LDFLAGS="-G -M $MATLAB/extern/lib/sol2/$MAPFILE"
            LDOPTIMFLAGS=''
            LDDEBUGFLAGS=''
#----------------------------------------------------------------------------
            ;;
        sun4)   # gcc version 2.6.3
#----------------------------------------------------------------------------
# A dry run of the appropriate compiler is done in the mex script to
# generate the correct library list. Use -v option to see what
# libraries are actually being linked in.
#----------------------------------------------------------------------------
            CC='gcc'
            CFLAGS='-ansi -Dsparc -DMEXSUN4'
            CLIBS="$MATLAB/extern/lib/sun4/libmex.a -lm"
            COPTIMFLAGS='-O -DNDEBUG'
            CDEBUGFLAGS='-g'
#
            FC='f77'
            FFLAGS=''
            FLIBS="$MATLAB/extern/lib/sun4/libmex.a -lm"
            FOPTIMFLAGS='-O'
            FDEBUGFLAGS='-g'
#
            LD='ld'
            LDFLAGS='-d -r -u _mex_entry_pt -u _mexFunction'
            LDOPTIMFLAGS='-x'
            LDDEBUGFLAGS=''
#----------------------------------------------------------------------------
            ;;
    esac
#############################################################################
#
# Architecture independent lines:
#
#     Set and uncomment any lines which will apply to all architectures.
#
#----------------------------------------------------------------------------
#           CC="$CC"
#           CFLAGS="$CFLAGS"
#           COPTIMFLAGS="$COPTIMFLAGS"
#           CDEBUGFLAGS="$CDEBUGFLAGS"
#           CLIBS="$CLIBS"
#
#           FC="$FC"
#           FFLAGS="$FFLAGS"
#           FOPTIMFLAGS="$FOPTIMFLAGS"
#           FDEBUGFLAGS="$FDEBUGFLAGS"
#           FLIBS="$FLIBS"
#
#           LD="$LD"
#           LDFLAGS="$LDFLAGS"
#           LDOPTIMFLAGS="$LDOPTIMFLAGS"
#           LDDEBUGFLAGS="$LDDEBUGFLAGS"
#----------------------------------------------------------------------------
#############################################################################
