function this = SimpleMotionProcess(varargin)
%function this = SimpleMotionProcess
%A simple motion process. It has a bound.

origin = [0 0];
onset = 0;
dx = [0.75 0.0];
dt = 0.15;
angle = 0;
color = [1 1 1];

this = autoobject(varargin{:});

counter_ = 0;

    function [x, y, t, a, c] = next()
        x = origin(1) + counter_ * dx(1);
        y = origin(2) + counter_ * dx(2);
        t = onset + counter_ * dt;
        a = angle;
        c = color;
        
        counter_ = counter_ + 1;
    end

    function b = bounds(t)
        %given a time since motion onset, return a bounds (which are really
        %a point)
        distance = dx * (t - onset) / dt;
        b = [origin origin] + [distance distance];
    end
end
