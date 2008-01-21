function checker = circularWindowExit(fieldname1, fieldname2, loc, radius)
    checker = @c;
    
    function [t, k] = c(k)
        t = sqrt((k.(fieldname1)-loc(1)).^2 + (k.(fieldname2)-loc(2)).^2) >= radius;
    end
end