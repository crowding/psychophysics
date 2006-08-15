function this = OutsideTrigger(obj_, fn_)
%Produces an object that fires a trigger when [x, y] is outside an object.

this = inherit(Identifiable(), public(@check));

    function check(x, y, t)
        if ~inrect(obj_.bounds(), x, y)
            fn_(x, y, t); %call function when eye is inside
        end
    end

    function draw(window, toPixels)
        Screen('FrameRect', window, [255 0 0], toPixels(obj_.bounds()));
    end

end