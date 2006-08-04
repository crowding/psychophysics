function this = Trigger
    %the Trigger interface.
    this = public(...
        @check,...
        @id...
    );
    
    function check(x, y, t)
    end

    function i = id
    end
end