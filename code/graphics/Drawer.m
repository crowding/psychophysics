function this = Drawer
%The interface for drawable objects.

this = inherit(...
    Identifiable,...
    public(@prepare, @release, @update, @draw, @bounds, @toPixels, @toDegrees)...
    );

    toPixels_ = [];
    toDegrees_ = [];

    function prepare(drawing)
        toPixels_ = transformToPixels(drawing.calibration());
        toDegrees_ = transformToDegrees(drawing.calibration());
        
        %in subclasses, calculate, build, textures, etc. for the given
        %display. Is a chained init function, need an inheritance idiom for
        %it rather than having to always remember to call the parent
        %function.
    end

    function release()
        %release any textures or other resources. Is a chained release 
        %function, need an inheritance mechanism for it.
    end

    function update()
        %this will be called once per notional frame regardless fo how many
        %actual frames are shown (use when you need to compensate for
        %skippage).
    end

    function draw()
        %this will be called once per drawn frame
    end

    function bounds
        %this should return the object bounds (in degrees);
    end

    function varargout = toPixels(varargin)
        varargout{1:nargout} = toPixels_(varargin{:});
    end

    function varargout = toDegrees(varargin)
        varargout{1:nargout} = toDegrees_(varargin{:});
    end
end