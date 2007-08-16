function this = CircularMotionProcess(varargin)
%Generates the motion of one or many objects appearing circularly in
%apparent motion.

    x = 0; %the center around which the sprite rotates
    y = 0;
    radius = 0; %the radius of the circle it/they move on
    phase = 0; %the initial phase
    angle = 0;
    color = [0.5;0.5;0.5];

    dphase = 0; %the phase angle change per appearance
    dt = 0.1; %the number of seconds per appearance
    n = Inf; %the number of appearances to show

    t = 0; %time of the first appearance

    counter_ = [0]; %counts how many of each target have been shown

    this = autoobject(varargin{:});

%-----
    
    function setPhase(p)
        phase = p;
        counter_ = zeros(size(p));
    end
    
    function [xx, yy, tt, aa, cc] = next()
        c = counter_;
        c(counter_ > n) = NaN;
        [tt, i] = min(t + c .* dt);
        
        if ~isnan(tt)
            xxx = x + radius .* cos(phase + dphase.*c);
            yyy = y - radius .* sin(phase + dphase.*c);
            aaa = angle + 180/pi .* dphase.*c;
            
            xx = xxx(i);
            yy = yyy(i);
            aa = aaa(i);
            
            if size(color, 2) > 1
                cc = color(:,i);
            else
                cc = color;
            end
            
            counter_(i) = counter_(i) + 1;
        else
            [xx, yy, tt, aa, cc] = deal(NaN);
        end
    end
end