function environment = env(key)
%Returns a structure containing path variables of use to the experiments.
%This si where I define my code's working directories.

persistent e;

if isempty(e)
    %this dir is the code dir
    e.codedir = fileparts(mfilename('fullpath'));

    %the base directory is the parent of the code directory
    e.basedir = fileparts(e.codedir);

    %experiment results are saved in the data dir, outside the trunk dir
    e.datadir = fullfile(fileparts(fileparts(e.codedir)), 'data');

    %calibrations are stored in a subdirectory
    e.calibrationdir = fullfile(e.datadir, 'calibration');

    %raw eyelink data is stored in another subdirectory
    e.eyedir = fullfile(e.datadir, 'eyelink');
end

if ~exist('key', 'var')
    environment = e;
else
    environment = e.(key);
end
