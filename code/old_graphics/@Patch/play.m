function play(this, w, cal);
% function play(this, window, calibration);
% render the patch and present it using psych toolbox.

if ~exist('cal', 'var') || ~exist('w', 'var')
	[w, cal, oldgamma] = open_window();
	closeWindow = 1;
else
	closeWindow = 0;
end

try
	t = texture_movie(this, w, cal)
	play_texture_movie(t, w);

	if closeWindow
		close_window(w, oldgamma)
	end
catch
	if closeWindow
		close_window(w, oldgamma)
	end
	rethrow(lasterror)
end
