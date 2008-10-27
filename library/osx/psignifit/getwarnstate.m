function s = getwarnstate
% GETWARNSTATE    R13 workaround
% 
% Workaround for the mutually incompatible behaviour of the WARNING command
% between post- and pre-R13 Matlab releases (also pre/post R14).
% 
% Example:
%     s = getwarnstate;
%     warning off
%     a = log(0:10);
%     setwarnstate(s)
% 
% See also SETWARNSTATE, POSTR13, POSTR14

% Part of the psignifit toolbox version 2.5.6 for MATLAB version 5 and up.
% Copyright (c) J.Hill 1999-2005.
% Please read the LICENSE and NO WARRANTY statement in psych_legal.m
% mailto:psignifit@bootstrap-software.org
% http://bootstrap-software.org/psignifit/

if postr13
	s = warning;
	s(end+1) = warning('query', 'backtrace');
	if ~postr14
		s(end+1) = warning('query', 'debug');
	end
	s(end+1) = warning('query', 'verbose');
else
	[s.state s.freq] = warning;
end
