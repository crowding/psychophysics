function this = UpdateTrigger(fn)
%A trigger that fires on every update.

this = public(...
    @check,...
    @id...
    );

%private members
    fn_ = fn;
    id_ = serialnumber();
    
    %methods
    function check(x, y, t)
        fn_(); %call function when eye is inside
    end

    function i = id
        i = id_;
    end
end