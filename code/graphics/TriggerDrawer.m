function this = TriggerDrawer(events_)

this = inherit(Drawer(), public(@draw, @visible, @setVisible));

    visible_ = 0;

    function draw(window)
        if visible_
            events_.draw(window, this.toPixels);
        end
    end

    function v = visible
        v = visible_;
    end

    function v = setVisible(v)
        visible_ = v;
    end

end