function this = InsideTrigger(rect, fn)
%Produces an object that fires a trigger when x and y are inside a rect.

this = public(...
    @check,...
    @id...
    );

%private members
    fn_ = fn;
    rect_ = rect;
    id_ = serialnumber();
    
    %methods
    function check(x, y, t)
        if inrect(rect_, x, y)
            fn_(); %call function when eye is inside
        end
    end

    function i = id
        i = id_;
    end
end