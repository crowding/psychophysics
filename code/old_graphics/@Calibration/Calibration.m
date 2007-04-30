function p = Calibration(varargin)
% function p = Calibration('propertyName', 'propertyValue')
%
% A set of calibration data. This includes frame 
% rate, angular spacing, and gamma correction information. 
%
% The object also includes machine name and color information so that a 
% calibration can be looked up.
% 
% Properties:
% 'machine' the machine name.
% 'screen' the screen number from psych-toolbox.
% 'distance' the distance from the screen to the observer's eye, in some units.
% 'spacing' the pixel spacing, in the same units.
% 'rect' the screen dimensions in pixels.
% 'pixelSize' the screen bit depth.
% 'interval' the frame interval in seconds (1 / refresh rate)
% 'gamma' A gamma correction table.
% 'calibration_rect' the rectangle that we placed the photometer over
% 'measurement' the raw gamma measurements.
% 'measured' set to true if the gamma table has been produced by photometric 
%  measurement.
% 'bitdepth' the bit depth of the gamma correction table.
%
% The constructor with no arguments will try to load the calibration from a 
% known location and match it to the current system. 
% 
% Methods:
% p = save(p) saves the calibration to a standard directory.
% p = load(p) finds the calibration that matches this computer and screen 
%             resolution.
% p = calibrate_gamma(p) speaks to a photometer on the given screen, and fills out 
%     its own gamma correction table.

classname = mfilename('class');
args = varargin;

if length(args) > 0 && isa(args{1}, classname)
	%copy constructor
	p = args{1};
	args = args(2:end);
else
	%default values to be IGNORED
	p.computer = NaN;
    p.ptb = NaN;
	p.screenNumber = NaN;
	p.distance = NaN;
	p.spacing = NaN;
	p.rect = NaN;
	p.pixelSize = NaN;
	p.interval = NaN;
	p.gamma = NaN;
	p.calibrated = NaN;
    p.calibration = NaN;
	p.bitdepth = NaN;
	p.date = NaN;
	 
    p.svn = svninfo(fileparts(mfilename('fullpath')));
	p = class(p, classname, PropertyObject);
end

if length(args) >= 2
	p = set(p, args{:});
end

%the real work: read the system for default values.
if isnan(p.computer)
	p.computer = Screen('Computer');
    p.computer = rmfield(p.computer, 'location'); %changes when network settings change
    p.computer.kern = rmfield(p.computer.kern, 'hostname'); %this changes all the time
    p.computer.hw = rmfield(p.computer.hw, 'usermem'); %this changes all the time
end

if isnan(p.ptb)
	p.ptb = Screen('Version');
    p.ptb = rmfield(p.ptb, 'authors'); %too long to dump out in our saved file
end

if isnan(p.screenNumber)
	p.screenNumber = max(Screen('screens'));
end
if isnan(p.rect)
	p.rect = Screen('Rect', p.screenNumber);
end
if isnan(p.pixelSize)
	p.pixelSize = Screen('PixelSize', p.screenNumber);
end
if isnan(p.interval)
	fr = Screen('FrameRate', p.screenNumber);
	if (fr == 0)
		warning('Calibration:noFrameRate', 'Unable to determine frame rate');
		fr=60;
	end
		
	p.interval = 1/fr;
end

%the above specifies system parameters; given this we should be able to find a
%saved calibration that matches.
[p, found] = load(p);

if ~found
	%if not, continue with initialization.
	if isnan(p.date)
		p.date = date();
	end
	if isnan(p.distance)
		p.distance = 50; %cm
	end
	if isnan(p.spacing)
		p.spacing = [0.025 0.025];
	end
	if isnan(p.gamma)
		p.gamma = Screen('ReadNormalizedGammaTable', p.screenNumber);
	end
	if isnan(p.calibrated)
		p.calibrated = 0;
	end
	if isnan(p.bitdepth)
		p.bitdepth = 8;
	end
end
