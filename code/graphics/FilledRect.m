function this = FilledRect(rect, color)

    %A filled rectangle object that is part of displays.
    visible = 0;
    
    this = finalize(inherit(autoprops(), automethods()));
    
    toPixels_ = @noop;
%----- methods -----

    function draw(window, next)
        if visible
            Screen('FillRect', window, color, toPixels_(rect));
        end
    end

    function b = bounds
        b = rect;
    end

    function [release, params] = init(params)
        toPixels_ = transformToPixels(params.cal);
        release = @noop;
    end

    function update()
        %nothing
    end

end
