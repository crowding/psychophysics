function p = CauchyPatch(varargin)
% function c = CauchyPatch([CauchyPatch], 'propname', value, ...)
% Constructor for Cauchy-shaped patches. The patch is a Cauchy function in 
% the X direction and is Gaussian in Y and T directions.
%
% Inherits from Patch.
%
% Additional Properties:
% 'size' a 3-vector [x, y, t] for setting the size of the patch. 
% In y and t, the values control the std. dev of the gaussian envelope; the x
% value controls the 1/2 wavelength.
% 
% 'velocity' approximately the spatial velocity in the x-direction.
% 'order' the order of the filter.

classname = mfilename('class');
args = varargin;

if length(args) > 0 && isa(args{1}, classname)
	%copy constructor
	p = args{1};
	args = args(2:end);
else
	%default values
	p.size = [1 1 0.5];
	p.velocity = 2;
	p.order = 4;
    p.phase = 0;

    p.svn = svninfo(fileparts(mfilename('fullpath')));
	p = class(p, classname, Patch);
end

%other initialization arguments
if length(args) >= 2
	p = set(p, args{:});
end
