function this = FilledBar(varargin)
    %A located, oriented bar. 

    x = 0;
    y = 0;
    length = 1;
    width = 0.2;
    color = [1 1 1 1];
    visible = 0;

    this = finalize(inherit ...
        ( autoprops(varagin(:)) ...
        , automethods() ...
    );

    toPixels_ = @noop;
    pixelsPerDegree = [0 0];

%------------
    function init(params)
        toPixels_ = transformToPixels(params.cal);
        pixelsPerDegree_ = 1./params.cal.spacing;
    end

    function draw(window, next)
        %convert the endpoints and width of the line to pixels
        length = [cos(angle*180/pi) - sin(angle*180/pi)] * (length/2);
        endpoints = toPixels_([x y x y] + [disp -disp]);
        
        %draw a line for me
        vec = [cos(angle*180/pi); -sin(angle*180/pi)] .* length/2;
        
        pxWidth = norm(width * [endpoints(2) endpoints(1)] .* resolution_);
        Screen('DrawLine', window, line, endpoints(1), endpoints(2), endpoints(3), endpoints(4), pxWidth);
    end

    function b = bounds()
        %The square around the enclosed circle?
        b = [x-length/2 y-length/2 x+length/2 y+length/2];
    end

    function update()
    end

end