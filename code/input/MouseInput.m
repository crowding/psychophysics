function this = MouseInput(varargin)
    %handles mouse input.

    persistent init__;
    this = autoobject(varargin{:});
    
    window_ = [];
    toDegrees_ = [];
    slowdown_ = [];
    xOffset = 0;
    yOffset = 0;
    
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
        
        %because of stupid bugginess in psychtoolbox, we cannot actually
        %trust it to get a relative mouse position. So we have to work out
        %the relative adjustment on our own.
        
        for i = 1:10 %hey, the mouse might be moving while we do this...
            rect = Screen('GlobalRect', window_);
            [x, y] = GetMouse(window_);
            SetMouse(rect(1), rect(2)); %this moves the ouse to what should be (0,0)
            [x1, y1] = GetMouse(window_);
            xOffset = x1;
            yOffset = y1;
            SetMouse(rect(1) + x - x1, rect(2) + y - y1);
            [x2, y2] = GetMouse(window_);
            if (x2 == x) || (y2 == y)
                break;
            end
        end
        if (x2 ~= x) || (y2 ~= y)
            error('MouseInput:mouseInputBroken', 'Could not find mouse position, Is Psychtoolbox even buggier than before?');
        end
    end

    %this function is called once per main loop iteration and actually
    %pulls in the data.
    function k = input(k)
        [k.mousex, k.mousey, k.mouseButtons] = GetMouse(window_);
        k.mousex = k.mousex - xOffset;
        k.mousey = k.mousey - yOffset;
        k.mouset = GetSecs() * slowdown_;
        [k.mousex_deg, k.mousey_deg] = toDegrees_(k.mousex, k.mousey);
    end

    function sync(n, t)
        %nothing needed
    end
end