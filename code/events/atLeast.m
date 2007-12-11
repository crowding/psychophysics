function f = atLeast(fieldname, value)
    f = @check;
    
    function [t, s] = check(s)
        if s.(fieldname) >= value
            s.triggerFieldName = fieldname;
            s.triggerValue = value;
            t = 1;
        else
            t = 0;
        end
    end
end
