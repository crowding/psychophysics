function this = Drawer
%The interface for drawable objects.

this = inherit(...
    Identifiable,...
    properties('visible', 0),...
    public(@prepare, @release, @draw, @bounds)...
    );

    function prepare(window, calibration)
        %calculate, build, textures, etc. for the given display.
    end

    function release()
        %release any textures or other resources
    end

end