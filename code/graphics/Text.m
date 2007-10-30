function this = Text(varargin)
%function this = Text(loc, text, color, varargin)

    loc = [0 0];
    text = '';
    color = [0 0 0];
    visible = 0;
    centered = 0;
    
    varargin = assignments(varargin, 'loc', 'text', 'color');

    this = autoobject(varargin{:});

    toPixels_ = 0;

    function draw(window, next)
        if ~visible
            return;
        end
        pix = toPixels_(loc);
        if centered
            bounds = Screen('TextBounds', window, text);
            pix = pix - (bounds([3 4]) - bounds([1 2])) ./ 2;
        end
        Screen('DrawText', window, text, pix(1), pix(2), color);
    end

    function [release, params] = init(params)
        toPixels_ = transformToPixels(params.cal);
        release = @noop;
    end

    function update(frames)
    end

    %simple getters/setters
    function t = getText
        t = text;
    end

    function t = setText(t)
        text = t;
    end

    function c = getColor
        c = color;
    end

    function c = setColor(c)
        color = c;
    end

    function l = getLoc
        l = loc;
    end

    function l = setLoc(l)
        loc = l;
    end

    function v = getVisible()
        v = visible;
    end

    function v = setVisible(v)
        visible = v;
    end
end
