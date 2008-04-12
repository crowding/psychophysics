function f = atLeast(fieldname, value)
%function f = atLeast(fieldname, value) a trigger condition.
    f = @check;
    
    function [t, s] = check(s)
        t = s.(fieldname) >= value;
        if any(t)
            s.triggerFieldName = fieldname;
            s.triggerValue = value;
            t = 1;
        else
            t = 0;
        end
    end
end
