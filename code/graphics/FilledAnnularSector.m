function this = FilledDisk(varargin)
%function this = FilledDisk(loc_, width_, color_)
%A graphics object that draws a disk at a specified location.
%
%loc : the coordinates (in degrees) of the center of the disk.
%radius: the radius of the disk in degrees.
%color: the color of the disk.
%
%See also Drawer, Drawing.

visible = 0;
loc = [0;0];
innerRadius = [1];
outerRadius = [2];
startAngle = 0; %here measured in radians
arcAngle = pi/2; %the arc length in radians
color = [0 0 0];
pixelAccuracy = 0.1; %the accuracy in pixels.

persistent init__;
this = autoobject(varargin{:});

toPixels_ = [];
degreePerPixel_ = [];

%----- methods -----

    onsetTime_ = 0;
    function draw(window, next)
        if visible
            l = e(loc, next - onsetTime_);

            %Compute a polygon:

            %the maximum pixel deviation and the radius determine
            %the maximum sector angle
            nSectors = ceil(arcAngle/acos(1/(1+pixelAccuracy*degreePerPixel_/outerRadius)));

            %correct the radius to have constant area
            %area of circle sector: sector*radius^2
            %area of regular polygon sector: cos(sector/2)*sin(sector/2)*r^2
            sector = arcAngle/nSectors;
            r1 = sqrt(innerRadius.^2 * sector/cos(sector/2)/sin(sector/2)/2);
            r2 = sqrt(outerRadius.^2 * sector/cos(sector/2)/sin(sector/2)/2);
            
            pts = [l(1)+r1*cos(startAngle+arcAngle*(0:nSectors-1)/nSectors) ...
                   l(1)+r2*cos(startAngle+arcAngle*(nSectors-1:-1:0)/nSectors);...
                   l(2)-r1*sin(startAngle+arcAngle*(0:nSectors-1)/nSectors)...
                   l(2)-r2*sin(startAngle+arcAngle*(nSectors-1:-1:0)/nSectors)];
            Screen('FillPoly', window, color, toPixels_(pts)');
        end
    end

    function b = bounds
        disp = repmat(radius, 1, 2);
        center = loc;
        b = ([center - disp, center + disp]);
    end

    function [release, params] = init(params)
        [src, dst] = Screen('BlendFunction', params.window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                    
        toPixels_ = transformToPixels(params.cal);
        degreePerPixel_ = 1./max(max(abs(toPixels_(0,0) - toPixels_(0,1))),max(abs(toPixels_(0,0) - toPixels_(1,0))));
        release = @unblend;
        function unblend
            Screen('BlendFunction', params.window, src, dst);
        end
    end

    function update(frames)
    end

    function v = getVisible
        v = visible;
    end

    function v = setVisible(v, t)
        visible = v;
        if nargin >= 2
            %track the onset time..
            onsetTime_ = t;
        end
    end

    function l = getLoc(t)
        if nargin > 0
            l = e(loc, t - onsetTime_);
        else
            l = loc;
        end
    end

    function l = setLoc(l)
        if isnumeric(l) && isvector(l)
            loc = l(:);
        else
            loc = l;
        end
    end

    function r = getOuterRadius
        r = outerRadius;
    end

    function r = setOuterRadius(r)
        outerRadius = r;
    end

    function r = getInnerRadius
        r = innerRadius;
    end

    function r = setInnerRadius(r)
        innerRadius = r;
    end

    function c = getColor
        c = color;
    end

    function c = setColor(c)
        color = c;
    end
end
