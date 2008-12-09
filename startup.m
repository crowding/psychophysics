%startup file for peter.
%prepare path for eyelink project.
run('~/eyetracking/setpath.m');
cd('~/eyetracking/');
if usejava('jvm')
    AddPsychJavaPath;
end
addpath('~/eyetracking/switchbox');
addpath('~/eyetracking/switchbox/shadow');