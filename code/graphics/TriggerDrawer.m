function this = TriggerDrawer(main_)
%function this = TriggerDrawer(main_)
%
%Draws the triggers.
%Make sure to call set() after creation to point it mack to the main loop.

this = final(@draw, @getVisible, @setVisible, @update, @init, @set);

    visible_ = 0;
    toPixels_ = [];

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

    function update(frames)
    end
    
    function set(m)
        main_ = m;
    end

    function [release, params] = init(params)
        toPixels_ = transformToPixels(params.cal);
        release = @noop;
    end

end
