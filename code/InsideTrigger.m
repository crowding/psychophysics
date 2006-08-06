function this = InsideTrigger(obj_, fn_)
%An object that fires a trigger when x and y are inside the bounds of a
%graphics object.

this = inherit(Identifiable(), public(@check));
    
    function check(x, y, t)
        if inrect(obj_.bounds(), x, y)
            fn_(x, y, t); %call function when eye is inside
        end
    end
end