function this = Drawer
%The interface for drawable objects.

this = inherit(...
    Identifiable,...
    public(@prepare, @release, @visible, @setVisible, @draw, @bounds)...
    );

    visible_ = 0;

    function prepare(window, calibration)
        %calculate, build, textures, etc. for the given display.
    end

    function release()
        %release any textures or other resources
    end

    function v = visible
        v = visible_;
    end

    function setVisible(v)
        visible_ = v;
    end
end