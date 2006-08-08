function this = FilledRect(loc__, size__, color__)

%A filled rectangle object that is part of displays.

%----- public interface -----
this = inherit(...
    Drawer(),...
    properties('loc', loc__, 'size', size__, 'color', color__),...
    public(@draw, @bounds)...
    );

%----- methods -----

    function draw(window)
        if this.visible()
            center = this.loc();
            Screen('gluDisk', window, this.color(), center(1), center(2), this.size());
        end
    end

    function b = bounds
        b = this.rect_;
    end
end