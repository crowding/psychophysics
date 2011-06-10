function this = Text(varargin)
%function this = Text(loc, text, color, varargin)

    loc = [0 0];
    text = '';
    color = [0 0 0];
    visible = 0;
    centered = 0;
    points = 12;
    style = 0;
    
    varargin = assignments(varargin, 'loc', 'text', 'color');

    persistent init__;
    this = autoobject(varargin{:});

    toPixels_ = 0;
    background_ = [];

    function draw(window, next)
        oldStyle = Screen('TextStyle', window, style);
        oldSize = Screen('TextSize', window, points);
        if ~visible
            return;
        end
        pix = toPixels_(loc);
        %split on newlines. Note MATLAB has no excapes and no newlines
        %allowed in strings, so must represent in sprintf(wtf)
        lines = splitstr(sprintf('\n'),text);
        
        bounds = zeros(numel(lines),4);
        for i = 1:numel(lines)
            bounds(i,:) = Screen('TextBounds', window, lines{i});
        end
        height = cumsum(bounds(:,4) - bounds(:,2));
        height = height - height(1);
        bounds(:,2) = bounds(:,2) + height;
        bounds(:,4) = bounds(:,4) + height;
        
        if centered
            pix = pix - (bounds(end,[3 4]) - bounds(1,[1 2])) ./ 2;
        end
        pix = round(pix);
        
        for i = 1:numel(lines)
            Screen('DrawText', window, lines{i}, pix(1), pix(2) + height(i), color, background_);
        end
    end

    function [release, params] = init(params)
        toPixels_ = transformToPixels(params.cal);
        background_ = params.backgroundIndex;
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
