function this = SimpleCircularGratingSource(varargin)
%and phase for each patch to be drawn on the screen.
%
%angles are in radians.
%
%inputs are the timestamp of the next scheduled frame, and the number of
%that frame.

    loc = [0;0];
    radius = 5;
    width = 1;
    lobes = 42;
    color = [0.5;0.5;0.5];
    phase = 0;
    omega = 2*pi;

    persistent init__;
    this = autoobject(varargin{:});

    function [xy, rad, wid, col, lob, ph] = get(time)
        xy = loc;
        rad = radius;
        wid = width;
        col = color;
        lob = lobes;
        ph = phase + omega * time;
    end
end