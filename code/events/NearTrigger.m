function this = NearTrigger(loc_, threshold_, fn_)
%An object that fires a trigger when x and y is within a certain distance
%to a point.

this = final(@check, @draw, @set, @unset, @setLog, @getFn);

if (nargin == 0)
    set_ = 0;
else
    set_ = 1;
end

log_ = [];
        
    function check(s)
        if set_ && (norm([s.x s.y] - loc_) <= threshold_)
            log_('TRIGGER %s %s', func2str(fn_), struct2str(s));
            fn_(s); %call function when eye is inside
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

    function setLog(log)
        log_ = log;
    end

    function fn = getFn()
        fn = fn_;
    end
end