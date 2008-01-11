function this = KeyboardInput(varargin)
    %handles keyboard input.
    %single liner test/profile:
    %a = KeyboardInput; r = a.init(struct()); r2 = a.begin(struct()); for i = 1:10000; k = a.input(struct()), end; r2(); r();

    persistent init__;
    this = autoobject(varargin{:});
    
    device = [];
    options = struct...
        ( 'secs', 0 ...
        , 'print', 0 ...
        );

    slowdown_ = [];
    [lastState_, lastState_, lastState_] = KbCheck(device);
    lastState_ = find(lastState_);
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
        
        release = @stop;
        PsychHID('ReceiveReports', device, options);
        PsychHID('GiveMeReports', device); %discard
        lastState_ = [];
        modifierCodes_ = KbName({'LeftControl','LeftShift','LeftAlt','LeftGUI','RightControl','RightShift','RightAlt','RightGUI'});
        
        function stop
            PsychHID('ReceiveReportsStop', device);
        end
    end

    %this initializer will be called once per trial and does local setup.
    function [release, params] = begin(params)
        if isfield(params, 'slowdown')
            slowdown_ = params.slowdown;
        end
        PsychHID('ReceiveReports', device, options);
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
        %better...
        if ~isempty(r)
            k.keyT = r(end).time ./ slowdown_;
            %The USB keyboard sends a report on every state change.
            %the first byte of the keyboard report bitmasks modifier keys
            %as listed above:
            last = r(end).report;

            keycodes = sort([modifierCodes_(logical(dec2bin(last(1)) - '0')) last(find(last(2:6))+1)]);

            lastState_ = keycodes;
            %Bytes 2-6 get all the keys that are pressed (if more than 5
            %keys are pressed, we get all ones here, just as in KbCheck)
            k.keycodes = keycodes;
            k.keyIsDown = ~isempty(keycodes);
        else
            k.keyT = GetSecs();
            k.keyIsDown = ~isempty(lastState_);
            k.keycodes = lastState_;
        end
    end

    function sync(n)
        %nothing needed
    end
end