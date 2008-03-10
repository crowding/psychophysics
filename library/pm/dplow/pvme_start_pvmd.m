function info=pvme_start_pvmd(conf,block)
%PVME_START_PVMD
%	Start PVM daemon.
%
%	Synopsis:
%		info = pvme_start_pvmd(conf,block)
%
%	Parameters:
%		conf	String or multi-string matrix containig one of the
%			following things:
%
%			Nothing: In this case a pvmd without any arguments
%			is started.
%
%			'd': In this case a default pvm configuration is
%			started, how it has been specified with 
%			pvme_default_config.
%
%			Arguments for pvmd3: for example:
%			conf = ['-dmask        ';
%			        '-nname        ';
%			        '/path/hostfile']
%			which are used to start pvm.
%			(This is just not implemented)
%
%			Arguments for pvmd3 and configuration information
%			like in a hostfile: for example:
%			conf = ['-dmask        ';
%			        '-nname        ';
%			        '* ep=/path_to/executable_dir']
%			which are used to start pvm.
%			
%		block	Integer scalar specifying wheter to block (~=0) until
%			startup of all hosts complete or (==0) return imme-
%			diately.
%
%		info	Integer scalar returning the status code. Values less
%			than zero indicate an error.
%		   	Error Value	  Possible cause
%			PvmDupHost	  A pvmd is already running.
%			PvmSysErr	  The local pvmd is not responding.
%			PvmeErr
%
%	After calling pvm_start_pvmd a PVM is running, but the caller isn't a
%	PVM task yet.
%
%	Matlab for LNX86 (i.e. Linux) detects a segmentation violation while
%	executing pvm_start_pvmd(3PVM), because stream descriptors are used
%	in this routine. Therefore, a bypass using a stand alone caller for
%	pvm_start_pvmd(3PVM) is implemented for this platform. For correct
%	operation of the bypass it is neccessary to add the dplow/ directory
%	of the DP-Toolbox to the shell search path.
%
%	See also: man pvm_start_pvmd(PVM3), pvmd3(PVM3)

%	Copyright (c) 1995-1999 University of Rostock, Germany, 
%	Institute of Automatic Control. All rights reserved.
%	Author: S. Pawletta

info = m2pvm(105,conf,block);

