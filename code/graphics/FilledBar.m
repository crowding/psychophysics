function this = FilledBar(varargin)
    %A located, oriented bar to be drawn to the screen.

    x = 0;
    y = 0;
    length = 1;
    width = 0.2;
    color = [1 1 1 1];
    visible = 0;
    angle = 0;

    this = finalize( inherit(autoprops(varargin{:}), automethods()) );

    toPixels_ = @noop;
    pixelsPerDegree_ = [0 0];

%------------
    function [release, params] = init(params)
        toPixels_ = transformToPixels(params.cal);
        pixelsPerDegree_ = 1./params.cal.spacing;
        [src, dst] = Screen('BlendFunction', params.window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        
        %set the blend function... this will clobber other blend function
        %settings in other objects
        release = @resetBlend;
        
        function resetBlend
            Screen('BlendFunction', params.window, src, dst);
        end
    end

    function draw(window, next)
        %convert the endpoints and width of the line to pixels
        if visible
            vec = [cos(angle*pi/180), -sin(angle*pi/180)];
            degHalfLength = vec * (length/2);
            endpoints = toPixels_([x x; y y] + [degHalfLength' -degHalfLength']);

            %pixel width of the bar (this compensates for anisotropic screen resolutions)
            pxWidth = norm(width * [vec(2) vec(1)] .* pixelsPerDegree_);

            %TODO: compensate for spatial frequency transfer functions
            %depending on orientation?

            %draw a line for me
            %need to set a blend function...
            Screen('DrawLines', window, endpoints, pxWidth, color, [0 0], 1);
        end
    end

    function b = bounds()
        %The square around the enclosed circle?
        b = [x-length/2 y-length/2 x+length/2 y+length/2];
    end

    function update()
    end

end