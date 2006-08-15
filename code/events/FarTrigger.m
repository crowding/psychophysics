function this = FarTrigger(obj_, threshold_, fn_)
%Produces an object that fires a trigger when [x, y] is outside an object's
%bounds plus an adjustable leeway.

this = inherit(Trigger(), public(@check, @draw));

    function check(x, y, t)
        if ~inrect(obj_.bounds() + threshold_*[-1 -1 1 1], x, y)
            fn_(x, y, t); %call function when eye is inside
        end
    end

    function draw(window, toPixels)
        Screen('FrameRect', window, [255 0 0], toPixels(obj_.bounds() + threshold_*[-1 -1 1 1]));
    end
end
