function p = Patch(varargin)
% function p = Patch([x, y, t])
% A spatiotemporal function.
% 
% Patch is a base class for spatiotemporal stimuli. Patch objects know their 
% support (the extent over which they evaluate nonzero) and have a settable
% center (mu). They can be asked to evaluate over a meshgrid-like range of 
% x, y, t values.
% 
% Properties:
% 'Center' the location [x, y, t] of the function. Default value [ 0 0 0 ].
%
% Methods:
% [x, y, t] = extent(p) returns the bounds over which the function is non-zero.
% z = evaluate(p, x, y, t) evaluates the function over the grid formed by 
% vectors x y and t.

classname = mfilename('class');
args = varargin;

if length(args) > 0 && isa(args{1}, classname)
	%copy constructor
	p = args{1};
	args = args(2:end);
else
	%default values
	p.center = [0 0 0];
        p.svn = svninfo(fileparts(mfilename('fullpath')));
	p = class(p, classname, PropertyObject);
end


%other initialization arguments
if length(args) >= 2
	p = set(p, args{:});
end
