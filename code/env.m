function e = env();
%Returns a structure containing path variables of use to the motion experiments

%this dir is the code dir
e.codedir = fileparts(mfilename('fullpath'));

%the base directory is hte parent of the code directory
e.basedir = fileparts(e.codedir);

%experiment results are saved in the data dir
e.datadir = fullfile(fileparts(e.codedir), 'data');

%calibrations are stored in a subdirectory
e.calibrationdir = fullfile(e.datadir, 'calibration');

%raw eyelink data is stored in another subdirectory
e.eyedir = fullfile(e.datadir, 'eyelink');
