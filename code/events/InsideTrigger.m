function this = InsideTrigger(bounds_, range_, offset_, fn_)
%An object that fires a trigger when x and y are inside the bounds of a
%graphics 
if nargin == 3
    set_ = 1;
else
    set_ = 0;
end

log_ = [];

this = inherit(Trigger(), public(@check, @draw, @set, @unset, @setLog));

    function check(x, y, t, next)
        if set_ && inRect(...
                bounds_() + range_ .* [-1 -1 1 1] + [offset_, offset_],...
                x, y)
            log_('TRIGGER %f, %f, %f, %f, %s', x, y, t, next, func2str(fn_));
            fn_(x, y, t, next); %call function when eye is inside
        end
    end

    function set(bounds, range, offset, fn)
        range_ = range;
        offset_ = offset;
        fn_ = fn;
        bounds_ = bounds;
        set_ = 1;
    end

    function unset()
        set_ = 0;
    end

    function draw(window, toPixels)
        if set_
            Screen('FrameRect', window, [0 255 0],...
                toPixels(bounds_() + range_ .*[-1 -1 1 1] + [offset_, offset_]));
        end
    end

    function setLog(log)
        log_ = log;
    end
end