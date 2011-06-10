function this = FilledDisk(varargin)
%function this = FilledDisk(loc_, width_, color_)
%A graphics object that draws a disk at a specified location.
%
%loc : the coordinates (in degrees) of the center of the disk.
%radius: the radius of the disk in degrees.
%color: the color of the disk.
%
%See also Drawer, Drawing.

dotType = 1;
visible = 0;
loc = [0;0];
radius = [1];
color = [0 0 0];
pixelAccuracy = 0.1; %the accuracy in pixels.


varargin = assignments(varargin, 'loc', 'radius', 'color');
setLoc(loc);
persistent init__;
this = autoobject(varargin{:});

toPixels_ = [];
degreePerPixel_ = [];

%----- methods -----

    onsetTime_ = 0;
    function draw(window, next)
        try
            if visible
                l = e(loc, next - onsetTime_);
                r = e(radius, next - onsetTime_);
                
                center = toPixels_(l);
                shifted = l; shifted(1,:)  = shifted(1,:) + r;

                %hmmm. note this assumes isotropic pixel spacing.
                sz = sqrt(sum((center - toPixels_(shifted)).^2));
                %if any(sz > 32)
                    %Technique 1 was FillOval.
                    
                    %technique 2 is gluDisk.
                    %gluDisk uses a small number of points...                    
                    %Screen('gluDisk', window, color, center(1,:), center(2,:), sz);

                    %Technique 3 involves computing our own polygon:
                    
                    %the maximum pixel deviation and the radius determine
                    %the maximum sector angle
                    nSectors = ceil(2*pi/acos(1/(1+pixelAccuracy*degreePerPixel_/r)));
                    
                    %correct the radius to have constant area
                    %area of circle sector: sector*radius^2
                    %area of regular polygon sector: cos(sector/2)*sin(sector/2)*r^2
                    sector = 2*pi/nSectors;
                    r = sqrt(r.^2 * sector/cos(sector/2)/sin(sector/2)/2);
                    pts = permute(cat(3, bsxfun(@plus, l(1,:), r*sin(2*pi*(0:nSectors-1)'/nSectors)), ...
                           bsxfun(@plus, l(2,:), r*cos(2*pi*(0:nSectors-1)'/nSectors))), [1 3 2]);
                    
                    for i = 1:size(pts, 3)
                        Screen('FillPoly', window, color, toPixels_(pts(:,:,i)')',1);
                    end
                %else
                    %GL points will work for us and are antialiased.
                    %On a slow computer they seem to slow down as the size changes for some
                    %reason.
                %    Screen('DrawDots', window, center, sz*2, color, [0 0], dotType);
                %end
            end
        catch
            rethrow(lasterror);
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

    function r = getRadius
        r = radius;
    end

    function r = setRadius(r)
        radius = r;
    end

    function c = getColor
        c = color;
    end

    function c = setColor(c)
        color = c;
    end

end
