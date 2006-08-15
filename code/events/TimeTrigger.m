function this = TimeTrigger(time__, fn_)
%Produces an object fires a trigger when a certain time has passed.
%The object has a unique serial number.

%----- public interface -----
this = inherit(Identifiable(), public(@check), properties('time', time__));

%----- methods -----
    function check(x, y, t)
        if (t >= this.time())
            fn_(x, y, t);
        end
    end
end