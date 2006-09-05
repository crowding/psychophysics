function this = TriggerDrawer(main)

this = inherit(Drawer(), public(@draw, @getVisible, @setVisible));

    visible_ = 0;

    function draw(window)
        if visible_
            events_.drawTriggers(window, this.toPixels);
        end
    end

    function v = getVisible
        v = visible_;
    end

    function v = setVisible(v)
        visible_ = v;
    end

end
