function p = Bar(varargin)
% function c = Bar([Bar], 'propname', value, ...)
% Constructor for stationary light bars.
%
% Inherits from Patch.
%
% Additional Properties:
% 'size' a 3-vector [x, y, t] for setting the size of the bar. 

classname = mfilename('class');
args = varargin;

if length(args) > 0 && isa(args{1}, classname)
	%copy constructor
	p = args{1};
	args = args(2:end);
else
	%default values
	p.size = [.2 1 .1];
	p.svn = svninfo(fileparts(mfilename('fullpath')));
	p = class(p, classname, Patch);
end

%other initialization arguments
if length(args) >= 2
	p = set(p, args{:});
end
