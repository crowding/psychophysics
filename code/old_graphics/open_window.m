function [w, cal, oldgamma] = open_window(screenNumber);
% function [w, cal] = open_window([screenNumber]);
% Open the window, fill it with gray, and set up the correct gamma function.
% Return a window pointer and the calibration to use.
% 
% If screenNumber is not given, uses the screen with highest number.

AssertOpenGL;
if ~exist('screenNumber', 'var')
	screenNumber = max(Screen('Screens'));
end

try
	%set black gamma before opening the window to avoid distraction
	oldgamma = Screen('ReadNormalizedGammaTable', screenNumber);
	Screen('LoadNormalizedGammaTable', screenNumber, zeros(256,3));
	
	w = Screen('OpenWindow', screenNumber, 0, [], 32);
	depth = Screen('PixelSize', screenNumber)
	black = BlackIndex(screenNumber);
	white = WhiteIndex(screenNumber);
	gray = (white + black)/2;

	Screen('FillRect', w, gray);
	Screen('Flip', w);
	Screen('FillRect', w, gray);

	%load the gamma table
	Screen('LoadNormalizedGammaTable', screenNumber, oldgamma);
	cal = Calibration();
	Screen('LoadNormalizedGammaTable', screenNumber, get(cal, 'gamma'));
	
catch
	if exist('w', 'var')
		try
			Screen('Close', w);
		end
	end
	%reset gamma
	if exist('oldgamma', 'var')
		try
			Screen('LoadNormalizedGammaTable', screenNumber, oldgamma);
		end
	end
	rethrow(lasterror);
end
