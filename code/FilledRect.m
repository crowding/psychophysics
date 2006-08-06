function this = FilledRect(initRect, initColor)

%A filled rectangle object that is part of displays.

%----- public interface -----
this = inherit(...
    Drawer(),...
    public(@rect, @setRect, @color, @setColor, @draw, @bounds)...
    );

%----- instance variables -----
rect_ = initRect;
color_ = initColor;

%----- methods -----
    function r = rect
        r = rect_;
    end

    function setRect(newrect)
        rect_ = newrect;
    end

    function c = color
        c = color
    end

    function setColor(newcolor)
        color_ = newcolor;
    end

    function draw(window)
        if this.visible()
            Screen('FillRect', window, color_, rect_);
        end
    end

    function b = bounds
        b = rect_;
    end

end