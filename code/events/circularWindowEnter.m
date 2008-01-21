function checker = circularWindowExit(fieldname1, fieldname2, loc, radius)
    checker = @c;
    
    function [t, s] = c(s)
        t = sqrt((s.(fieldname1)-loc(1)).^2 + (s.(fieldname2)-loc(2)).^2) <= radius;
    end
end