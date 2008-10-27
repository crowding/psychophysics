function p = postr13
% POSTR13    is this release of Matlab R13 or later?
% 
% TheMathWorks (gawd bless 'em and their versioning system) made enough
% changes between Release 12 and Release 13 that a substantial amount of
% existing code breaks. This would be tolerable if it weren't for several
% cases of mutual incompatibility, (e.g. the '-V4' flag to MEX is supported
% under R12 and below, but causes an error in R13, whereas the '-V5' flag,
% which would be the nearest equivalent under R13, causes an error in R12).
% 
% POSTR13 lets you know whether you're in the post-R13 era or not, to help
% you program around the fact that TMW are trying to make your life
% difficult.

% Part of the psignifit toolbox version 2.5.6 for MATLAB version 5 and up.
% Copyright (c) J.Hill 1999-2005.
% Please read the LICENSE and NO WARRANTY statement in psych_legal.m
% mailto:psignifit@bootstrap-software.org
% http://bootstrap-software.org/psignifit/

global POSTR13FLAG
if isempty(POSTR13FLAG)
	test = '(datenum(version(''-date'')) >= datenum(''Jun 18 2002''))';
	POSTR13FLAG = eval(test, 'logical(0)');
end
p = POSTR13FLAG;
