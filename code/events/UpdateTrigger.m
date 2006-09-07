function this = UpdateTrigger(fn_)
%A trigger that calls its function on every update.
%
%See also Trigger.

this = final(@check, @set, @unset, @setLog, @draw);

if (nargin < 1)
    set_ = 0;
else
    set_ = 1;
end

log_ = [];

    %methods
    function check(x, y, t, next)
        if set_
            log_('TRIGGER %f, %f, %f, %f, %s', x, y, t, next, func2str(fn_));
            fn_(x, y, t, next); %call function always
        end
    end

    function set(fn)
        fn_ = fn;
        set_ = 1;
    end

    function unset()
        set_ = 0;
    end

    function setLog(log)
        log_ = log;
    end

    function draw(window, toPixels)
    end
end