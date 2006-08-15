function this = NearTrigger(obj_, threshold_, fn_)
%An object that fires a trigger when x and y are "near" the bounds of a
%graphics object, with an adjustable amount of leeway.

this = inherit(Trigger(), public(@check, @draw));
    
    function check(x, y, t)
        if inRect(obj_.bounds() + threshold_*[-1 -1 1 1], x, y)
            fn_(x, y, t); %call function when eye is inside
        end
    end

    function draw(window, toPixels)
        Screen('FrameRect', window, [0 255 0], toPixels(obj_.bounds() + threshold_*[-1 -1 1 1]));
    end
end
