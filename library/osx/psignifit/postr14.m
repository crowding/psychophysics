function p = postr14
% POSTR14    is this release of Matlab R14 or later?
% 
% They've done it again with their mutual incompatibilities between releases!
% Thank you, TMW, for making toolbox maintenance such an uphill struggle.
% 
% See also POSTR13

% Part of the psignifit toolbox version 2.5.6 for MATLAB version 5 and up.
% Copyright (c) J.Hill 1999-2005.
% Please read the LICENSE and NO WARRANTY statement in psych_legal.m
% mailto:psignifit@bootstrap-software.org
% http://bootstrap-software.org/psignifit/

global POSTR14FLAG
if isempty(POSTR14FLAG)
	test = '(datenum(version(''-date'')) >= datenum(''May 6 2004''))';
	POSTR14FLAG = eval(test, 'logical(0)');
end
p = POSTR14FLAG;
