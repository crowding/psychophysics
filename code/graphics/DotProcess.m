function this = DotProcess(bounds_, density_)

    %the dot process generates events within a rectangular window with a
    %certain density of events per second per square degree. 

    this = final(@next, @getBounds, @setBounds, @getDensity, @setDensity);
    t_ = 0;

    function [x, y, t, a, color] = next()
        rate = (bounds_(3) - bounds_(1)) * (bounds_(4) - bounds_(2)) * density_;
        interval = -log(rand) / rate;
        t = t_ + interval;
        t_ = t;
        x = bounds_(1) + rand * (bounds_(3) - bounds_(1));
        y = bounds_(2) + rand * (bounds_(4) - bounds_(2));
        a = rand * 360;
        
        %the 'color' is an RGBA column vector, here chosen with random RBG
        %and full alpha.
        color = [rand(3, 1); 1];
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
end