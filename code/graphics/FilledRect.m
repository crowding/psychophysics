function this = FilledRect(rect__, color__)

%A filled rectangle object that is part of displays.

%----- public interface -----
this = inherit(...
    Drawer(),...
    properties('visible', 0, 'rect', rect__, 'color', color__),...
    public(@draw, @bounds)...
    );

%----- methods -----

    function draw(window)
        if this.getVisible()
            Screen('FillRect', window, this.getColor(), this.toPixels(this.getRect()));
        end
    end

    function b = bounds
        b = this.getRect();
    end
end
