function this = UpdateTrigger(fn_)
%A trigger that fires on every update.
this = inherit(Trigger(), public(@check, @set, @unset));

    if (nargin < 1)
        set_ = 0;
    else
        set_ = 1;
    end
    
    %methods
    function check(x, y, t)
        if set_
            fn_(x, y, t); %call function always
        end
    end

    function set(fn)
        fn_ = fn;
        set_ = 1;
    end

    function unset()
        set_ = 0;
    end
end