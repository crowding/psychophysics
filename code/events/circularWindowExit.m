function checker = circularWindowExit(fieldname1, fieldname2, timefield, loc, radius)
    checker = @c;
    
    function [t, k] = c(k)
        l = e(loc, k.(timefield));
        t = sqrt((k.(fieldname1)-l(1,:)).^2 + (k.(fieldname2)-l(2,:)).^2) >= radius;
    end
end