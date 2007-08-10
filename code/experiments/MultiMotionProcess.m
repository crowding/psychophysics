function this = MultiMotionProcess(varargin)
%function this = MultiMotionProcess
%A multiple motion process. Each object has an independent onset time
%and an independent offset time. 

%some default things...
onsetX = [0 0];
onsetY = [0 0];
onsetT = [0 0];
dx = [0.75 0.0];
dy = [0.0 0.75];
dt = [0.15 0.15];
orientation = [0 90];
%color is one column per object
color = [0.5 0.5; 0.5 0.5; 0.5 0.5;];

%one private variable...
counter_ = [0 0];

this = autoobject(varargin{:});

    function setOnsetT(o)
        onsetT = o;
        %and there is a counter for each.
        counter_ = zeros(size(o));
    end

    function setColor(c)
        color = c;
    end

    function [x, y, t, a, c] = next()
        %pick the next one...
        [t,i] = min(onsetT + counter_.*dt);
        x = onsetX(i) + counter_(i) * dx(i);
        y = onsetY(i) + counter_(i) * dy(i);
        a = orientation(i);
        c = color(:,i);
        
        counter_(i) = counter_(i) + 1;
    end

    function b = bounds(t)
        %given a time since motion onset, the bounds is the location of the
        %FIRST point.
        b = [onsetX(1) onsetY(1) onsetX(1) onsetY(1)] + (t - onsetT(1)) * [dx(1) dy(1) dx(1) dy(1)] / dt(1);
    end
end
