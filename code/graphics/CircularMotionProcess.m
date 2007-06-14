function this = CircularMotionProcess(varargin)
%Cenerates the motion of one or many objects appearing circularly in
%apparent motion.

    x = 0; %the center around which the sprite rotates
    y = 0;
    radius = 0; %the radius of the circle it moves on
    phase = 0; %the initial phase
    angle = 0;
    color = [1 1 1 1];

    dphase = 0; %the phase angle change per appearance
    dt = 0.1; %the number fo seconds per appearance
    n = Inf; %the number of appearances left to show

    t = 0; %time of the first appearance

    this = finalize ( inherit( autoprops(varargin{:}), automethods() ) );

%-----
    counter_ = 1;
    
    function [xx, yy, tt, aa, cc] = next()
        if (n > 0)
            xx = x + radius .* cos(phase);
            yy = y - radius .* sin(phase);
            aa = angle;
            
            xx = xx(counter_);
            yy = yy(counter_);
            aa = aa(counter_);
            tt = t(counter_);
            
            cc = color;

            if counter_ >= max([ numel(xx), numel(yy), numel(aa), numel(tt) ]);
                phase = phase + dphase;
                angle = angle + dphase * 180 / pi;
                n = n - 1;
                t = t + dt;
                counter_ = 1;
            else
                counter_ = counter_ + 1;
            end
        end
    end
end