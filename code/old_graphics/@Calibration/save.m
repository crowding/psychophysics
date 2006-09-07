function this = save(this);
% function this = save(this);
%
% Saves this calibration to a known location so that it can be recalled.

filename = strcat(this.computer.machineName, '.mat');
dirs = env;
file = fullfile(dirs.calibrationdir, filename);

%in each file is an array called "calibrations," we append this latest one 
%to the array.

if exist(file, 'file')
	s = load(file);
else
	s = struct;
end

if isfield(s, 'calibrations');
	if ~isa(s.calibrations, class(this))
		error('type mismatch between object to save and existing file.');
	end
	s.calibrations = cat(1, s.calibrations, this);
else
	s.calibrations = this;
end

save(file, '-struct', 's');
