function checker = circularWindowEnter(fieldname1, fieldname2, timefield, loc, radius)
    checker = @c;
    
    function [t, s] = c(s)
        l = e(loc, s.(timefield));
        t = sqrt((s.(fieldname1)-l(1,:)).^2 + (s.(fieldname2)-l(2,:)).^2) <= radius;
    end
end