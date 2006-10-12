function p = CauchyBar(varargin)
% function c = CauchyBar([CauchyBar], 'propname', value, ...)
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

%default values
defaults = struct ...
    ( 'size', [0.5 1 0.05] ...
    , 'phi' , 0 ...
    , 'velocity', 10 ...
    , 'order', 4 ...
    , 'svn', svninfo(fileparts(mfilename('fullpath'))) ...
    );

p = class(defaults, classname, Patch);

p = namedargs(p, varargin{:});