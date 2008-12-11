%startup file for peter.
%prepare path for eyelink project.
run('~/eyetracking/setpath.m');
cd('~/eyetracking/');
if usejava('jvm')
    AddPsychJavaPath;
end
s = Screen('Computer');
if strcmp(s.machineName, 'pastorianus')
    addpath('~/eyetracking/switchbox');
    addpath('~/eyetracking/switchbox/shadow');
end
clear s;