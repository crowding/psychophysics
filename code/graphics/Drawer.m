function this = Drawer
%The interface for drawable objects.

this = inherit(...
    Identifiable,...
    properties('visible', 0),...
    public(@prepare, @release, @draw, @bounds, @toPixels, @toDegrees)...
    );

    toPixels_ = [];
    toDegrees_ = [];

    function varargout = toPixels(varargin)
        varargout{1:nargout} = toPixels_(varargin{:});
    end

    function varargout = toDegrees(varargin)
        varargout{1:nargout} = toDegrees_(varargin{:});
    end


    function prepare(calibration, window)
        toPixels_ = transformToPixels(calibration);
        toDegrees_ = transformToDegrees(calibration);
        
        %in subclasses, calculate, build, textures, etc. for the given
        %display.
    end

    function release()
        %release any textures or other resources
    end

end