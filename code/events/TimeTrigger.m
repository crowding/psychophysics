function this = TimeTrigger(time_, fn_)
%Produces an object fires a trigger when a certain time has passed.
%The object has a unique serial number.

%----- public interface -----
this = inherit(Trigger(), public(@check, @set, @unset, @draw));

%----- instance variables -----
if (nargin == 0)
    set_ = 0;
else
    set_ = 1;
end

%----- methods -----
    function check(x, y, t)
        if set_ && (t >= time_)
            fn_(x, y, time_); %pretend it was triggered on exact time
        end
    end

    function set(time, fn)
        time_ = time;
        fn_ = fn;
        set_ = 1;
    end

    function unset()
        set_ = 0;
    end

    function draw(window, toPixels)
        %draw the seconds remaining
        if set_
            t = time_ - GetSecs();
            Screen('DrawText', window, sprintf('%0.3f', t), 20, 20, [0 255 0] );
        end
    end
        
end