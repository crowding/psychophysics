
function this = ConcentricDemo(varargin)
%show glolo concentric in a circle around the fixation point. Verious
%button presses adjust the position...

    x = AdjustableDemo();
    %TODO this should really be "with" defaults...
    %defaults('set','KeyboardInput', 'device', 7);
    playDemo(x, varargin{:}, 'skipFrames', 1);
end

