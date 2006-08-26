function this = NearTrigger(loc_, threshold_, fn_)
%An object that fires a trigger when x and y is within a certain distance
%to a point.

this = inherit(Trigger(), public(@check, @draw, @set, @unset));

    if (nargin == 0)
        set_ = 0;
    else
        set_ = 1;
    end
        
    function check(x, y, t, next)
        if set_ && (norm([x y] - loc_) <= threshold_)
            fn_(x, y, t, next); %call function when eye is inside
        end
    end
    
    function set(loc, threshold, fn)
        loc_ = loc;
        threshold_ = threshold;
        fn_ = fn;
        
        set_ = 1;
    end

    function unset()
        set_ = 0;
    end

    function draw(window, toPixels)
        if set_
            Screen('FrameOval', window, [0 255 0],...
                toPixels([loc_ loc_] + threshold_*[-1 -1 1 1]) );
        end
    end
end
