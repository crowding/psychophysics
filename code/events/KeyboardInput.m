function this = KeyboardInput(varargin)
    %handles keyboard input.

    this = autoobject(varargin{:});
    
    keyboardDevice = [];
    slowdown_ = [];
    
    %the initializer will be called once per experiment and does global
    %setup of everything.
    function [release, params] = init(params)
        if isempty(keyboardDevice)
            devices = PsychHID('devices');
            ix = find(strcmp('Keyboard', {devices.usageName}));
            if isempty(ix)
                error('KeyboardInput:noKeyboardFound', 'no keyboard device found');
            end
            kbIndex = ix(1);
        end
        
        release = @noop;
    end

    %this initializer will be called once per trial and does local setup.
    function [release, params] = begin(params)
        if isfield(params, 'slowdown')
            slowdown_ = params.slowdown;
        end
        %nothing for keyboard
        release = @noop;
    end

    %this function is called once per main loop iteration and actually
    %pulls in the data.
    function k = input(k)
        [k.keyIsDown, k.keyT, k.keyCode] = KbCheck(keyboardDevice);
        k.keyT = k.keyT ./ slowdown_;
    end
end