function p = TestGrating(varargin)
% function c = TestGrating([TestGrating], 'propname', value, ...)
% Constructor for test gratings. THe test grating evaluates to black or
% white on alternate pixels, to check that when we draw things to the
% screen in OpenGL we are respecting pixel boundaries.
%
% Inherits from Patch.
%
% Additional Properties:
%
% 'size' a 3-vector [x, y, t] for setting the size of the bar. 
%
% 'spacing' a 3-vector [x, y, t] showing how many 'spaces' in the
% evaluation before it changes over. E.g. [1, Inf Inf] is a 1-pixel
% vertical grating, [2 2 Inf] is a 2-pixel checkerboard, and [Inf Inf 1]
% flips form black to white every frame.

classname = mfilename('class');
args = varargin;

if length(args) > 0 && isa(args{1}, classname)
	%copy constructor
	p = args{1};
	args = args(2:end);
else
	%default values
	p.size = [1 1 1];
    p.spacing = [2 2 Inf];
	p.svn = svninfo(fileparts(mfilename('fullpath')));
	p = class(p, classname, Patch);
end

%other initialization arguments
if length(args) >= 2
	p = set(p, args{:});
end
