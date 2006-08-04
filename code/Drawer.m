function this = Drawer
%The interface for drawable objects.

this = public(...
    @prepare...
    ,@release...
    ,@setVisible...
    ,@draw...
    ,@bounds...
    ,@id...
    );

    function prepare(window, calibration)
        %calculate, build, textures, etc. for the given display.
    end

    function release()
        %release any textures or other resources
    end

    function setVisible(visible)
        %set the interface for drawable objects.
    end

    function v = visible
        %tells whether the object is visible.
    end

    function draw(window)
        %Draws the object (and advances one frame).
    end

    function b = bounds
        %returns the bounds of the object, on the next frame of draw().
    end

    function i = id
        %the serial number identifier of the object.
    end
end