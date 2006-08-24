function this = InsideTrigger(obj_, fn_)
%An object that fires a trigger when x and y are inside the bounds of a
%graphics object.
if nargin == 2
    set_ = 1;
else
    set_ = 0;
end

this = inherit(Trigger(), public(@check, @draw, @set, @unset));

    function check(x, y, t)
        if set_ && inRect(obj_.bounds(), x, y)
            fn_(x, y, t); %call function when eye is inside
        end
    end

    function set(obj, fn)
        obj_ = obj;
        fn_ = fn;
        set_ = 1;
    end

    function unset()
        set_ = 0;
    end

    function draw(window, toPixels)
        if set_
            Screen('FrameRect', window, [0 255 0], toPixels(obj_.bounds()));
        end
    end
end