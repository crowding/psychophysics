function this = Calibration2(varargin)

computer = NaN;
ptb = NaN;
screenNumber = NaN;
distance = NaN;
spacing = NaN;
rect = NaN;
pixelSize = NaN;
interval = NaN;
gamma = NaN;
calibrated = NaN;
calibration = NaN;
bitdepth = NaN;
date = NaN;
center = NaN;

persistent init__
this = autoobj(varargin);

%the real work: read the system for default values.
if isnan(computer)
	computer = Screen('Computer');
    computer = rmfield(computer, 'location'); %changes when network settings change
    computer.kern = rmfield(computer.kern, 'hostname'); %this changes all the time
    computer.hw = rmfield(computer.hw, 'usermem'); %this changes all the time
end

l = localExperimentParams();

if isnan(ptb)
	ptb = Screen('Version');
    ptb = rmfield(ptb, 'authors'); %too long to dump out in our saved file
end

if isnan(screenNumber)
    if isfield(l, 'ScreenNumber')
    	screenNumber = l.screenNumber;
    else
        screenNumber = max(Screen('Screens'));
    end
end
if isnan(rect)
	rect = Screen('Rect', screenNumber);
end
if isnan(pixelSize)
	pixelSize = Screen('PixelSize', screenNumber);
end
if isnan(interval)
	fr = Screen('FrameRate', screenNumber);
	if (fr == 0)
		warning('Calibration:noFrameRate', 'Unable to determine frame rate');
		fr=60;
	end
		
	interval = 1/fr;
end

if isnan(center)
    center = [0 0]; %measured in degrees from the center of the screen
end

%the above specifies system parameters; given this we should be able to find a
%saved calibration that matches.
%[p, found__] = load(p);
found__ = [];

if ~found__
	%if not, continue with initialization.
	if isnan(date)
		date = date();
	end
	if isnan(distance)
		distance = 50; %cm
	end
	if isnan(spacing)
		spacing = [0.025 0.025];
	end
	if isnan(gamma)
%%%		gamma = Screen('ReadNormalizedGammaTable', screenNumber);
        gamma = linspace(0,1,256)' * [1 1 1];
	end
	if isnan(calibrated)
		calibrated = 0;
	end
	if isnan(bitdepth)
		bitdepth = 8;
	end
end
