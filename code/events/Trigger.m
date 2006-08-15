function this = Trigger
    %the Trigger interface.
    this = inherit(Identifiable(), public(@check, @draw));
    
    function check(x, y, t)
    end

    function draw(window, toPixels)
    end
end