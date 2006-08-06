function this = UpdateTrigger(fn_)
%A trigger that fires on every update.
this = inherit(Identifiable(), public(@check));

    %methods
    function check(x, y, t)
        fn_(x, y, t); %call function when eye is inside
    end
end