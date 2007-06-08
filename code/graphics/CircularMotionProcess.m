function this = CircularMotion(varargin)
%Cenerates the motion of one or many objects appearing circularly in
%apparent motion.

    %object properties
    x_ = 0; %the center around which the sprite rotates
    y_ = 0;
    radius_ = 0; %the radius of the circle it moves on
    phase_ = 0; %the initial phase
    angle_ = 0;
    color_ = [1 1 1 1];

    dphase_ = 0; %the phase angle change per appearance
    dt_ = 0.1; %the number fo seconds per appearance
    n_ = Inf; %the number of appearances left to show

    t_ = 0; %time of the first appearance

    %Shows a patch (or patches) moving around in a circle.

    this = finalize ( inherit ...
        ( autoprops(varargin{:}) ...
        , public( @next ) ...
    ) );

    counter = 1;
    
    function [x, y, t, a, c] = next()
        if (n_ > 0)
            xx = x_ + radius_ .* cos(phase_);
            yy = y_ - radius_ .* sin(phase_);
            aa = angle_;
            
            x = xx(counter);
            y = yy(counter);
            a = aa(counter);
            t = t_(counter);
            
            c = color_;

            if counter >= max([ numel(xx), numel(yy), numel(aa), numel(t) ]);
                phase_ = phase_ + dphase_;
                angle_ = angle_ + dphase_ * 180 / pi;
                n_ = n_ - 1;
                t_ = t_ + dt_;
                counter = 1;
            else
                counter = counter + 1;
            end
        end
    end
end