function this = TriggerDrawer(main)

this = final(@draw, @getVisible, @setVisible, @update, @init);

    visible_ = 0;
    toPixels_ = [];

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

    function update()
    end

    function [release, params] = init(params)
        toPixels_ = transformToPixels(params.cal);
        release = @noop;
    end

end
