function this = FilledDisk(loc__, radius__, color__)

%A filled rectangle object that is part of displays.

%----- public interface -----
this = inherit(...
    Drawer(),...
    properties('loc', loc__, 'radius', radius__, 'color', color__),...
    public(@draw, @bounds)...
    );

%----- methods -----

    function draw(window)
        if this.visible()
            center = this.toPixels(this.loc());
            corner = this.toPixels(this.loc() + repmat(this.radius(), 1, 2));
            rad = norm(corner - center);
            Screen('gluDisk', window, this.color(), center(1), center(2), rad);
        end
    end

    function b = bounds
        disp = repmat(this.radius(), 1, 2);
        center = this.loc();
        b = ([center - disp center + disp]);
    end
end