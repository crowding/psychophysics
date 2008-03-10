function putenv(STR)
%PUTENV	Change or add an environment variable.
%
%	PUTENV('STR'), where STR is a text string of the 
%	form NAME=VALUE. If NAME does not already exist in
%	the environment, then NAME is added to the environment.
%	If NAME does exist, then the value of NAME in the
%	environment is changed to value. Nothing is returned.

%	Copyright (c) 1995-1999 University of Rostock, Germany, 
%	Institute of Automatic Control. All rights reserved.
%	Author: S. Pawletta (1995, initial version as c0_putenv)
%			    (Dec 98, renamed to putenv)

% implemented as MEX function
