function this = KeyboardInput(varargin)
    %handles keyboard input.
    %single liner test/profile:
    %a = KeyboardInput; r = a.init(struct()); r2 = a.begin(struct()); for i = 1:10000; k = a.input(struct()); end; r2(); r();

    this = autoobject(varargin{:});
    
    device = [];
    options = struct...
        ( 'secs', 0 ...
        , 'print', 0 ...
        );

    slowdown_ = [];
    lastState_ = [];
    modifierCodes_ = [];
    
    %the initializer will be called once per experiment and does global
    %setup of everything.
    function [release, params] = init(params)
        if isempty(device)
            devices = PsychHID('devices');
            ix = find(strcmp('Keyboard', {devices.usageName}));
            if isempty(ix)
                error('KeyboardInput:noKeyboardFound', 'no keyboard device found');
            end
            device = ix(1);
        end
        
        release = @noop;
        PsychHID('ReceiveReports', device);
        PsychHID('GiveMeReports', device); %discard
        lastState_ = false(size(getOutput(3, @()KbCheck(device))));
        modifierCodes_ = KbName({'LeftControl','LeftShift','LeftAlt','LeftGUI','RightControl','RightShift','RightAlt','RightGUI'});
    end

    %this initializer will be called once per trial and does local setup.
    function [release, params] = begin(params)
        if isfield(params, 'slowdown')
            slowdown_ = params.slowdown;
        end
        PsychHID('ReceiveReports', device);
        PsychHID('GiveMeReports', device); %discard
        ListenChar(2); %disable keyboard input to matlab...

        release = @stop;
        function stop();
            ListenChar(0);
        end
    end

    %this function is called once per main loop iteration and actually
    %pulls in the data.
    function k = input(k)
        %KbCheck is RIDICULOUSLY slow (i.e. matlab spends a lot of time
        %waiting around for nothing) compared to the alternative: reading
        %the interrupt reports directly from PsychHID.
        
        %[k.keyIsDown, k.keyT, k.keyCode] = KbCheck(device);
        %k.keyT = k.keyT ./ slowdown_;
        
        PsychHID('ReceiveReports', device, options);
        r = PsychHID('GiveMeReports', device);
        %process reports. Note that this discards reports in an attempt to
        %be more like kbCheck()! But it is possible to check the keyboard
        %and make it more like 
        if ~isempty(r)
            k.keyT = r(end).time ./ slowdown_;
            %The USB keyboard sends a report on every state change.
            %the first byte of the keyboard report bitmasks modifier keys
            %as listed above:
            keymap = false(size(lastState_));
            last = r(end).report;
            if last(1) > 0
                keymap(modifierCodes_(logical(dec2bin(last(1)) - '0'))) = 1;
            end
            
            %Bytes 2-6 get all the keys that are pressed (if more than 5
            %keys are pressed, we get all ones here, just as in KbCheck)
            last = last(2:6);
            keymap(last(last ~= 0)) = 1;
            k.keyIsDown = any(keymap);
            k.keyCode = keymap;
        else
            k.keyT = GetSecs();
            k.keyIsDown = any(lastState_);
            k.keyCode = lastState_;
        end
    end
end