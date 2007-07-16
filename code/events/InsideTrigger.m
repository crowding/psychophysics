function this = InsideTrigger(bounds_, range_, offset_, fn_)
%An object that fires a trigger when x and y are inside the bounds of a
%graphics object.
if nargin == 4
    set_ = 1;
else
    set_ = 0;
end

log_ = [];

this = final(@check, @draw, @set, @unset, @setLog, @getFn);

    function check(s)
        if set_ && inRect(...
                bounds_() + range_ .* [-1 -1 1 1] + [offset_, offset_],...
                s.x, s.y)
            log_('TRIGGER %s %s', func2str(fn_), struct2str(s));
            fn_(s); %call function when eye is inside
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
            bounds = bounds_();
            Screen('FrameRect', window, [0 255 0],...
                toPixels(bounds + range_ .*[-1 -1 1 1] + [offset_, offset_]));
            ll = toPixels(bounds([1 4]) + range_ .* [-1 1] + offset_);
            Screen('DrawText', window, func2str(fn_), ll(1), ll(2), [0 255 0], 0);
        end
    end

    function setLog(log)
        log_ = log;
    end

    function fn = getFn()
        fn = fn_;
    end
end