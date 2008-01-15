function f = atLeast(fieldname, value)
%function f = atLeast(fieldname, value) a trigger condition.
    f = @check;
    if nargin < 3
        timefield = 'next';
    end
    
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
