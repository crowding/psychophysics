function r = close_window(w, oldgamma);

if exist('oldgamma', 'var')
	Screen('LoadNormalizedGammaTable', w, oldgamma);
end

Screen('Close', w);
