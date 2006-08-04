function this = TimeTrigger(time, fn)
%Produces an object fires a trigger when a certain time has passed.
%The object has a unique serial number.

%----- public interface -----
this = public(...
    @check,...
    @id...
    );

%----- private members -----
fn_ = fn;
time_ = time;
id_ = serialnumber();

%----- methods -----
    function check(x, y, t)
        if (t >= time_)
            fn_();
        end
    end

    function i = id
        i = id_;
    end
end