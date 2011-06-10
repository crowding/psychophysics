
function this = ConcentricDemo(varargin)
%show glolo concentric in a circle around the fixation point. Verious
%button presses adjust the position...

    x = AdjustableDemo();
    playDemo(x, varargin{:}, 'skipFrames', 0)
end

