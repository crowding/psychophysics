function this = Text(loc_, text_, color_)
%this = Text(loc_, text_, color_)

    visible_ = 0;

    this = inherit(Drawer(), ...
        public(@draw, @bounds, ...
        @getText, @setText, @getColor, @setColor, @getLoc, @setLoc, @getVisible, @setVisible));

    function draw(window)
        loc = this.toPixels(loc_);
        Screen('DrawText', window, text_, loc(1), loc(2), color_);
    end
    
    %----- dumb accessors -----
    function t = getText
        t = text_;
    end

    function t = setText(t)
        text_ = t;
    end

    function c = getColor
        c = color_;
    end

    function c = setColor(c)
        color_ = c;
    end

    function l = getLoc
        l = loc_;
    end

    function l = setLoc(l)
        loc_ = l;
    end

    function v = getVisible
        v = visible_;
    end

    function v = setVisible(v)
        visible_ = v;
    end
end
