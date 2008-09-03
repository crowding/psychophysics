function this = CircularCauchyMotion(varargin)
%Generates the motion of one or many objects appearing circularly in
%apparent motion.

    x = 0; %the center around which the sprite rotates
    y = 0;
    radius = 0; %the radius of the circle it/they move on
    phase = 0; %the initial phase
    angle = 0;
    color = [0.5;0.5;0.5];
    
    wavelength = 1;
    width = 1;
    duration = 0.1;
    velocity = 10;
    localPhase = 0;
    order = 4;
    
    dphase = 0; %the phase angle change per appearance
    dt = 0.1; %the number of seconds per appearance
    n = Inf; %the number of appearances to show

    t = 0; %time of the first appearance

    counter_ = [0]; %counts how many of each target have been shown

    persistent init__;
    this = autoobject(varargin{:});

%-----
    
    function r = getRadius()
        r = radius;
    end

    function setPhase(p)
        phase = p;
        reset();
    end
    
    function s  = next()
               
        
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
            
            if numel(wavelength) > 1
                ll = wavelength(i);
            else
                ll = wavelength;
            end

            if numel(width) > 1
                ww = width(i);
            else
                ww = width;
            end

            if numel(duration) > 1
                dd = duration(i);
            else
                dd = duration;
            end
            
            if numel(velocity) > 1
                vv = velocity(i);
            else
                vv = velocity;
            end

            if numel(localPhase) > 1
                ph = localPhase(i);
            else
                ph = localPhase;
            end

            if numel(order) > 1
                or = order(i);
            else
                or = order;
            end
            
            counter_(i) = counter_(i) + 1;
        else
            [xx, yy, tt, aa, cc, ll, ww, dd, vv, ph, or] = deal([]);
        end
        
        s = struct('x', xx, 'y', yy, 't', tt, 'angle', aa, 'color', cc, 'wavelength', ll, 'width', ww, 'duration', dd, 'velocity', vv, 'phase', ph, 'order', or);
    end

    function reset()
        counter_ = zeros(size(phase));
    end
end