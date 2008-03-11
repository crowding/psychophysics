function this = AnnularDotProcess(bounds_, density_, color_)

    %the dot process generates events within an annular window with a
    %certain density of events per second per square degree. 
    %the annular sindow is specified as a center and radius: [x y inner
    %outer].

    this = final(@next, @getBounds, @setBounds, @getDensity, @setDensity, @getColor, @setColor, @reset);
    t_ = 0;

    function [x, y, t, a, c] = next()
        rate = pi * (bounds_(4)*bounds_(4) - bounds_(3)*bounds_(3)) * density_;
        interval = -log(rand) / rate;
        t = t_ + interval;
        t_ = t;
        
        %if events are uniformly distributed within the annulus, then here
        %is a random radius:
        r = sqrt(rand()*(bounds_(4).^2-bounds_(3).^2) + bounds_(3).^2);
        
        %and here a random angle:
        w = rand*2*pi;
        
        x = r * cos(w) + bounds_(1);
        y = r * sin(w) + bounds_(2);
        
        a = rand * 360;
        
        %the 'color' is an RGBA column vector, here chosen with random RBG
        %and full alpha.
        c = color_;
    end

    function bounds = getBounds()
        bounds = bounds_;
    end

    function setBounds(bounds)
        bounds_ = bounds;
    end

    function d = getDensity()
        d = density_;
    end

    function setDensity()
        density_ = d;
    end

    function color = getColor();
        color = color_;
    end

    function setColor(color);
        color_ = color;
    end

    function reset();
        
    end

end