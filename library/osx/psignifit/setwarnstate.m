function setwarnstate(s)
% SETWARNSTATE    R13 workaround
% 
% Workaround for the mutually incompatible behaviour of the WARNING command
% between post- and pre-R13 Matlab releases.
% 
% Example:
%     s = getwarnstate;
%     warning off
%     a = log(0:10);
%     setwarnstate(s)
% 
% See also GETWARNSTATE, POSTR13

% Part of the psignifit toolbox version 2.5.6 for MATLAB version 5 and up.
% Copyright (c) J.Hill 1999-2005.
% Please read the LICENSE and NO WARRANTY statement in psych_legal.m
% mailto:psignifit@bootstrap-software.org
% http://bootstrap-software.org/psignifit/

if postr13
	warning(s)
else
	warning(s.state)
	warning(s.freq)
end