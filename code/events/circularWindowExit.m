function checker = circularWindowExit(fieldname1, fieldname2, timefield, loc, radius)
    checker = @c;
    
    function [t, s] = c(s)
        t = sqrt([(s.(fieldname1)(:) - loc(1)) (s.(fieldname2)(:)-loc(2).^2)] * [1;1]) >= radius;
        if any(t)
            i = find(t, 1, 'first');
            s.triggerValue = [s.(fieldName1)(i) s.(fieldName2)(i)];
            s.triggerTime = s.(timefield)(i);
        end
    end
end