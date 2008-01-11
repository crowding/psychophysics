function f = magnitudeAtLeast(fieldname1, fieldname2, value)
%function f = magnitudeAtLeast(fieldname1, fieldname2, value) a trigger condition.
    f = @check;
    
    function [t, s] = check(s)
        t = sqrt(s.(fieldname1).^2 + s.(fieldname2).^2) >= value;
    end
end
