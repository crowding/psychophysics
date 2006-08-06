function this = FilledRect(x_, y_, size_, color_)

%A filled rectangle object that is part of displays.

%----- public interface -----
this = inherit(...
    Drawer(),...
    public(@loc, @setLoc, @color, @setColor, @size, @setSize, @draw, @bounds)...
    );

%----- methods -----

    function [x, y] = loc
        [x, y] = deal(x_, y_);
    end

    function setLoc(x, y)
        [x_, y_] = deal(x, y);
    end

    function c = color
        c = color
    end

    function setColor(newcolor)
        color_ = newcolor;
    end

    function s = size
        s = size_;
    end

    function setSize(s)
        size_ = s;
    end

    function draw(window)
        if this.visible()
            Screen('gluDisk', window, color_, x_, y_, size_);
        end
    end

    function b = bounds
        b = rect_;
    end
end