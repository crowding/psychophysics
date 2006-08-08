function this = FilledRect(loc_, size_, color_)

%A filled rectangle object that is part of displays.

%----- public interface -----
this = inherit(...
    Drawer(),...
    public(@loc, @setLoc, @color, @setColor, @size, @setSize, @draw, @bounds)...
    );

%----- methods -----

    function l = loc
        l = loc_;
    end

    function setLoc(l)
        loc_ = l;
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
            Screen('gluDisk', window, color_, loc_(1), loc_(2), size_);
        end
    end

    function b = bounds
        b = rect_;
    end
end