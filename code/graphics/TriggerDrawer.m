function this = TriggerDrawer()

this = final(@draw, @getVisible, @setVisible, @update, @init, @set);

    visible_ = 0;
    toPixels_ = [];
    main_ = [];

    function draw(window, next)
        if visible_
            main_.drawTriggers(window, toPixels_);
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
    
    function set(m)
        main_ = m;
    end

    function [release, params] = init(params)
        toPixels_ = transformToPixels(params.cal);
        release = @noop;
    end

end
