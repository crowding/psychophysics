function f = atLeast(fieldname, value, timefield)
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
            s.triggerTime = s.(timefield)(find(t, 1, 'first'));
            t = 1;
        else
            t = 0;
        end
    end
end
