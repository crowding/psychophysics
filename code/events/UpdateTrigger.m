function this = UpdateTrigger(fn_)
%A trigger that calls its function on every update.
%
%See also Trigger.

this = final(@check, @set, @unset, @setLog, @draw, @getFn);

if (nargin < 1)
    set_ = 0;
else
    set_ = 1;
end

log_ = [];

    %methods
    function check(s)
        if set_
            log_('TRIGGER %s %s', func2str(fn_), 'foo'); % struct2str(s));
            fn_(s); %call function always
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

    function fn = getFn()
        fn = fn_;
    end

    function draw(window, toPixels)
    end
end