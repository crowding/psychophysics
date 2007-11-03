function this = MouseInput(varargin)
    %handles mouse input.

    this = autoobject(varargin{:});
    
    window_ = [];
    toDegrees_ = [];
    slowdown_ = [];
    
    %the initializer will be called once per experiment and does global
    %setup of everything (i.e. configuring input hardware, expensive setup)
    function [release, params] = init(params)
        release = @noop;
    end

    %this initializer will be called once per trial and does trial setup
    %(i.e. starting/stopping recording, synchronizing, etc.)
    function [release, params] = begin(params)
        %nothing for mouse
        if isfield(params, 'slowdown')
            slowdown_ = params.slowdown;
        end
        window_ = params.window;
        toDegrees_ = transformToDegrees(params.cal);
        release = @noop;
    end

    %this function is called once per main loop iteration and actually
    %pulls in the data.
    function k = input(k)
        [k.mousex, k.mousey, k.mouseButtons] = GetMouse(window_);
        k.mouset = GetSecs() * slowdown_;
        [k.mousex_deg, k.mousey_deg] = toDegrees_(k.mousex, k.mousey);
    end
end