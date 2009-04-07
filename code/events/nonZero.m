function f = nonZero(fieldname, value)
%function f = nonZero(fieldname, value) a trigger condition.
    f = @check;
    
    function [t, s] = check(s)
        if any(s.(fieldname))
            s.triggerFieldName = fieldname;
            t = 1;
        else
            t = 0;
        end
    end
end
