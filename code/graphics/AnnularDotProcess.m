function this = AnnularDotProcess(varargin)

    %the dot process generates events within an annular window with a
    %certain density of events per second per square degree. 
    %the annular sindow is specified as a center and radius: [x y inner
    %outer].
    
    bounds = [0 0 3 5];
    density = 100;
    color = [1; 1; 1; 1];

    persistent init__;
    this = autoobject(varargin{:});
    t_ = 0;

    function [x, y, t, a, c] = next()
        rate = pi * (bounds(4)*bounds(4) - bounds(3)*bounds(3)) * density;
        interval = -log(rand) / rate;
        t = t_ + interval;
        t_ = t;
        
        %if events are uniformly distributed within the annulus, then here
        %is a random radius:
        r = sqrt(rand()*(bounds(4).^2-bounds(3).^2) + bounds(3).^2);
        
        %and here a random angle:
        w = rand*2*pi;
        
        x = r * cos(w) + bounds(1);
        y = r * sin(w) + bounds(2);
        
        a = rand * 360;
        
        %the 'color' is an RGBA column vector, here chosen with random RBG
        %and full alpha.
        c = color;
    end

    function reset()
        
    end

end