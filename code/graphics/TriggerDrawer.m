function this = TriggerDrawer(varargin)
%function this = TriggerDrawer(main_)
%
%Draws the triggers.
%Make sure to call set() after creation to point it mack to the main loop.

    main = [];
    visible = 0;

    varargin = assignments(varargin, 'main');
    
    persistent init__;
    this = autoobject(varargin{:});
    
    toPixels_ = [];

    function draw(window, next)
        if visible
            main_.drawTriggers(window, toPixels_);
        end
    end

    function v = getVisible
        v = visible;
    end

    function v = setVisible(v)
        visible = v;
    end

    function update(frames)
    end
    
    function set(m)
        main = m;
    end

    function [release, params] = init(params)
        toPixels_ = transformToPixels(params.cal);
        release = @noop;
    end

end
