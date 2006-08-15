function this = DisplayText(loc_, text_, color_)
    
    visible_ = 0;

    this = inherit(Drawer(), ...
        public(@draw, @bounds, ...
        @text, @setText, @color, @setColor, @loc, @setLoc, @visible, @setVisible));

    function draw(window)
        loc = this.toPixels(loc_);
        Screen('DrawText', window, text_, loc(1), loc(2), color_);
    end
    
    %----- dumb accessors -----
    function t = text
        t = text_;
    end

    function t = setText(t)
        text_ = t;
    end

    function c = color
        c = color_;
    end

    function c = setColor(c)
        color_ = c;
    end

    function l = loc
        l = loc_;
    end

    function l = setLoc(l)
        loc_ = l;
    end

    function v = visible
        v = visible_;
    end

    function v = setVisible(v)
        visible_ = v;
    end
end