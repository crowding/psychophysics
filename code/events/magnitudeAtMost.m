function f = magnitudeAtMost(fieldname1, fieldname2, timefield, value)
%function f = magnitudeAtLeast(fieldname1, fieldname2, value) a trigger condition.
    f = @check;
    
    function [t, s] = check(s)
        t = sqrt(s.(fieldname1).^2 + s.(fieldname2).^2) <= value;
        if any(t)
            i = find(t, 1, 'first');
            s.triggerValue = [s.(fieldname1)(i) s.(fieldname2)(i)];
            s.triggerTime = i;
        end
    end
end
