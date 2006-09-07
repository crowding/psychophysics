function [this, found] = load(this)
% function this = load(this)
%
% Looks for a previous calibration with the matching machine name and parameters
% (screen res, refresh rate), and returns the latest matching one. If none is 
% found, the present calibration is returned unchanged.

found = 0;
filename = strcat(this.computer.machineName, '.mat');
dirs = env;
file = fullfile(dirs.calibrationdir, filename);

if exist(file, 'file')
	s = load(file);
	if isa(s.calibrations, class(this))
		flipud(makecolumn(s.calibrations));
		for i = fliplr(makerow(s.calibrations));
			% match on machine, screenNumber, rect, interval
			if match(this, i)
				this = i;
				found = 1;
				return;
			end
		end
	end
end
