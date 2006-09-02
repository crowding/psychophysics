function this = Drawer
%The interface for drawable objects.

this = inherit(...
    Identifiable,...
    public(@prepare, @release, @init, @update, @draw, @bounds)...
    );
    function prepare(params)
        %in subclasses, calculate, build, textures, etc. for the given
        %display.
    end

    function release()
        %Should release any textures or other resources.
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

%----- prepare and release are invoked by this initializer function

    function [releaser, params] = init(params)
        this.prepare(params);
        releaser = this.release;
    end
end