function this = Text(loc_, text_, color_)
%this = Text(loc_, text_, color_)

    visible_ = 0;
    toPixels_ = 0;

    this = final(@draw, @bounds, ...
        @getText, @setText, ...
        @getColor, @setColor, ...
        @getLoc, @setLoc, ...
        @getVisible, @setVisible, ...
        @init, @update...
        );

    function draw(window, next)
        loc = toPixels_(loc_);
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

    function [release, params] = init(params)
        toPixels_ = transformToPixels(params.cal);
        release = @noop;
    end

    function update(frames)
    end
end
