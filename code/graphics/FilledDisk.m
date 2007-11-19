function this = FilledDisk(loc, radius, color, varargin)
%function this = FilledDisk(loc_, width_, color_)
%A graphics object that draws a disk at a specified location.
%
%loc_ : the coordinates (in degrees) of the center of the disk.
%radius_: the radius of the disk in degrees.
%color_: the color of the disk.
%
%See also Drawer, Drawing.

dotType = 1;
visible = 0;

persistent init__;
this = autoobject(varargin{:});

toPixels_ = [];

%----- methods -----

    function draw(window, next)
        if visible
            center = toPixels_(loc);
            sz = norm(center - toPixels_(loc + [radius 0]));
            Screen('DrawDots', window, center, sz*2, color, [0 0], dotType);
            %Screen('gluDisk', window, color, center(1), center(2), sz);
        end
    end

    function b = bounds
        disp = repmat(radius, 1, 2);
        center = loc;
        b = ([center - disp, center + disp]);
    end

    function [release, params] = init(params)
        toPixels_ = transformToPixels(params.cal);
        %set the blend function... this will clobber other blend function
        %settings in other objects
        [src, dst] = Screen('BlendFunction', params.window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        
        release = @resetBlend;
        
        function resetBlend
            Screen('BlendFunction', params.window, src, dst);
        end
    end

    function update(frames)
    end

    function v = getVisible
        v = visible;
    end

    function v = setVisible(v)
        visible = v;
    end

    function l = getLoc
        l = loc;
    end

    function l = setLoc(l)
        loc = l;
    end

%manually declare accessors, for speed inside the function.
%{
    function r = getRadius
        r = radius_;
    end

    function r = setRadius(l)
        radius_ = r;
    end

    function c = getColor
        c = color_;
    end

    function c = setColor(c)
        if ~exist('c', 'var')
            noop;
        end
        color_ = c;
    end
%}

end
