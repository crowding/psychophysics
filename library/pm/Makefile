#
# Makefile for the parallel Matlab toolbox
#

# PVM_ROOT and PVM_ARCH must be set in the environment.
# The environment variables in .cshrc must have been updated.
# (e.g. by 'source ~/.cshrc' or executing make from a new xterm)

# include the compiler and linker options for each platform

include conf/M$(PM_VER)_$(PVM_ARCH).mk


default:	inst

inst:
	@ echo "************** making files in pm/src  *************"
	cd src   $(CS) $(MAKE) install $(CS) cd ..

clean:
	- cd src    $(CS) $(MAKE) clean $(CS) cd ..

tidy:
	- cd src    $(CS) $(MAKE) tidy $(CS) cd ..


