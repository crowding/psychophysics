function r = testpath
addpath('/Users/peter/work/eyetracking/trunk/hacks/subdirOK');
rmpath('/Users/peter/work/eyetracking/trunk/hacks/subdirKO');
r = subfunction();
rmpath('/Users/peter/work/eyetracking/trunk/hacks/subdirOK');
addpath('/Users/peter/work/eyetracking/trunk/hacks/subdirKO');
end