function this = FilledRect(varargin)

    %A filled rectangle object that is part of displays.
    visible = 0;
    
    rect = [0 0 0 0];
    color = [0];
    
    persistent init__;
    varargin = assignments(varargin, 'rect', 'color');
    this = autoobject(varargin{:});
    
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

    function update(frames)
        %nothing
    end

end
