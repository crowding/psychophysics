function this = FilledDisk(loc_, radius_, color_)

%A filled rectangle object that is part of displays.

%----- public interface -----
this = inherit(...
    Drawer(),...
    public(...
        @draw, @bounds,...
        @loc, @setLoc, @radius, @setRadius,...
        @color, @setColor, @visible, @setVisible)...
    );

%----- private instance variables (plus those that are arguments) -----

toPixels_ = this.toPixels;
visible_ = 0;

%----- methods -----
    function draw(window)
        if visible_
            center = toPixels_(loc_);
            corner = toPixels_(loc_ + repmat(radius_, 1, 2));
            rad = norm(corner - center);
            Screen('gluDisk', window, color_, center(1), center(2), rad);
        end
    end

    function b = bounds
        disp = repmat(radius_, 1, 2);
        center = loc_;
        b = ([center - disp, center + disp]);
    end

%manually declare accessors, for speed inside the function.
    function l = loc
        l = loc_;
    end

    function l = setLoc(l)
        loc_ = l;
    end

    function r = radius
        r = radius_;
    end

    function r = setRadius(l)
        radius_ = r;
    end

    function c = color
        c = color_;
    end

    function c = setColor(c)
        color_ = c;
    end

    function v = visible
        v = visible_;
    end

    function v = setVisible(v)
        visible_ = v;
    end
end