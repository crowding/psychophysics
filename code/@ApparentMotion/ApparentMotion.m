function this = ApparentMotion(varargin)
% function c = ApparentMotion([CauchyPatch], 'propname', value, ...)
% Constructor for apparent motion simuli. The stimulus is composed of a 
% Patch that is repeated while moving over intervals of dx and dt.
%
% Inherits from Patch.
%
% Additional Properties:
% 'primitive' the Patch that is displayed at each station
% 'dx' the distance in x between showings of the primitive
% 'dt' the distance in y between showings of the primitive
% 'n' the number of frames

classname = mfilename('class');
args = varargin;

if length(args) > 0 && isa(args{1}, classname)
	%copy constructor
	this = args{1};
	args = args(2:end);
else
	%default values
	this.primitive = Bar;
	this.dx = 1;
	this.dt = 0.1;
	this.n = 10;
	this.svn = svninfo(fileparts(mfilename('fullpath')));
	this = class(this, classname, Patch);
end

%other initialization arguments
if length(args) >= 2
	this = set(this, args{:});
end
