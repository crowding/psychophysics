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
% 'center' the location [x, y, t] of the stimulus. Default value [ 0 0 0 ].
%
% Methods:
% [x, y, t] = extent(p) returns the bounds over which the function is non-zero.
% z = evaluate(p, x, y, t) evaluates the function over the grid formed by 
%                          vectors x y and t.

classname = mfilename('class');

defaults = struct ...
	( 'center', [0 0 0] ...
    , 'svn', svninfo(fileparts(mfilename('fullpath'))) ...
	);
p = class(defaults, classname, PropertyObject);

p = namedargs(p, varargin{:});