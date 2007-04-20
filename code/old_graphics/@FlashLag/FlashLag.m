function this = FlashLag(varargin)
% function c = FlashLag('property', value)
%
% A flash lag stimulus extends an apparent motion stimulus.
%
% It adds a second primitive 'flash' which is a white, 1/60 second bar by 
% default. 
%
% It adds the properties:
% 'when' the station next to which the flash appears
% 'ddx' the x-offset of the flash relative to that station.
% 'ddt' the t-offset of the flash relative to that station.
% 'ddy' the t-offset of the flash relative to that station. (currently no 
% support for flashes overlapping.

classname = mfilename('class');
args = varargin;

if length(args) > 0 && isa(args{1}, classname)
	%copy constructor
	this = args{1};
	args = args(2:end);
else
	%default values
	this.flash = Bar('size', [.1 1 1/60]);
	this.ddx = 0;
	this.ddt = 0;
	this.ddy = 1.5;
	this.when = 5;
	this.svn = svninfo(fileparts(mfilename('fullpath')));

    if length(args) > 0 && isstruct(args{1})
        p = args{1};
		args = args(2:end);
        parent = p.ApparentMotion;
        this = orderlike(this, p);
    else
		parent = ApparentMotion('n', 20, 'dx', 1, 'dt', 0.2, 'primitive', ...
						CauchyBar('velocity', 5, 'size', [ 0.5 1 0.1 ] ));
	end
	this = class(this, classname, parent);
end

%other initialization arguments
if length(args) >= 2
	this = set(this, args{:});
end
