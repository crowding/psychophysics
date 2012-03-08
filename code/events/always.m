function f = always()
%function f = always(fieldname, value) a trigger condition that always says yes.
    f = @check;
    
    function [t, s] = check(s)
        t = 1;
    end
end
