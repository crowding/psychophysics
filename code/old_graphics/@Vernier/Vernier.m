function this = Vernier(varargin)
% function c = Vernier([CauchyPatch], 'propname', value, ...)
% Constructor for apparent motion simuli. The stimulus is composed of a 
% Patch that is repeated while moving over intervals of dx and dt.
%
% Inherits from Patch.
%
% Additional Properties:
% 'primitive' the Patch that is displayed at each station
% 'dx' the distance in x between showings of the primitive
% 'dt' the distance in y between showings of the primitive
% 'ddx' the distance in x betweeen the first and second patches
% 'ddy' the distance in y betweeen the first and second patches
% 'ddp' the distance in y betweeen the first and second patches
% 'n' the number of jumps.
%
% Methods
% texture_movie(this, w, cal) creates the texture movie.

classname = mfilename('class');
args = varargin;

if length(args) > 0 && isa(args{1}, classname)
	%copy constructor
	this = args{1};
	args = args(2:end);
else
    %default values
    this.primitive = CauchyBar('size', [0.5 1 0.05], 'velocity', 10);
    this.dx = 1;
    this.center = [0 0 0];
    this.dt = 0.1;
    this.ddy = 1;
    this.ddx = 0;
    this.ddt = 0;
    this.ddp = 0;
    this.n = 10;
    this.svn = svninfo(fileparts(mfilename('fullpath')));

    if length(args) > 0 && isstruct(args{1})
    	p = args{1};
		args = args(2:end);
        parent = p.Patch;
        this = orderlike(this, p);
	else
	    parent = Patch;
    end
    this = class(this, classname, parent);
end

%other initialization arguments
if length(args) >= 2
	this = set(this, args{:});
end
