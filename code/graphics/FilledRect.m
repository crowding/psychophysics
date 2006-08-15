function this = FilledRect(rect__, color__)

%A filled rectangle object that is part of displays.

%----- public interface -----
this = inherit(...
    Drawer(),...
    properties('rect', rect__, 'color', color__),...
    public(@draw, @bounds)...
    );

%----- methods -----

    function draw(window)
        if this.visible()
            Screen('FillRect', window, this.color(), this.toPixels(this.rect()));
        end
    end

    function b = bounds
        b = this.rect();
    end
end