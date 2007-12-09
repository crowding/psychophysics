function this = PowermateInput(varargin)
%Event-handler Object for communicating with a Griffin Powermate controller.
%one liner test:
%a = PowermateInput; require(a.init,@()require(a.begin,@()arrayfun(@()eval('ans = a.input(struct()); a.knobPosition'),1:1000)));
%
%graphical:
%a = PowermateInput(); x = 1; t = []; clear y;
%require(a.init,@()require(a.begin,@()arrayfun(@(x)evalin('base','y(x) = a.input(struct()); x = x + 1;plot(1:min(100, numel(y)),[y(max(end-99, 1):end).knobPosition],1:min(100, numel(y)),[y(max(end-99, 1):end).knobRotation]);ylim([-100 100]); xlim([0 100]);drawnow()'),1:2000)));

device = [];

persistent init__; %#ok
this = autoobject(varargin{:});

position = 0;
button = 0;
options = struct...
    ( 'secs', 0 ...
    , 'print', 0 ...
    );

function d = discover()
    %scan for the PowerMate -- vendorID 1917, productID 1040
    d = PsychHID('devices');
    d = d(([d.vendorID] == 1917) & ([d.productID] == 1040));
    if isempty(device) && ~isempty(d)
        device = d(1).index;
    end
    d = [d.index];
end

function [release, params] = init(params)
    if isempty(device)
        discover();
        if isempty(device)
            error('powermate:noDeviceFound', 'No device found.');
        end
    end
    
    PsychHID('ReceiveReports', device, options);
    PsychHID('GiveMeReports', device);
    position = 0;
    button = 0;
    setBrightness(0);
    release = @noop;
end

function [release, params] = begin(params)
    position = 0;
    button = 0;
    release = @noop;
end

function s = input(s)
    PsychHID('ReceiveReports', device);
    r = PsychHID('GiveMeReports', device);
    
    if ~isempty(r)
        %we got at least one (possibly many) reports.
        data = double(cat(1, r.report));
        
        %byte 1 gives the button.
        buttons = data(:,1);
        transitions = diff([button; buttons]);
        button = buttons(end);
        
        %byte 2 is an int8 shift amount.
        shifts = data(:,2);
        shifts = shifts - (shifts>=128) * 256;
        shift = sum(shifts);
        
        %if any(abs(shifts) > 1)
        %    x = x + sum(shifts(abs(shifts) > 1));
        %end
        
        %{
        %The powermate is not a 1-1 device. It drops a count when the knob
        %reverses direction. But it also drops counts when the kno is
        %turning quickly?
        
        %sometimes you have a button press w/ no shift but we want to know
        %the last-known-direction at each step. Here's how to propagate it
        %forward:
        directions = sign(filter(1, [1 -0.5], sign(shifts)));
        
        reversals = abs(diff([direction;directions])) >= 1; %ignore the initial value...
        direction = directions(end); %remember the direction of last shift
        
        %compensate for the missing step...
        %shifts(reversals) = shifts(reversals) + directions(reversals);
        %}
        
        position = position + shift;
        s.knobPosition = position;
        s.knobRotation = shift;
        s.knobButton = button;
        
        %we output a count of knop pressings and releasings
        s.knobDown = sum(transitions > 0);
        s.knobUp = sum(transitions < 0);
        s.knobTime = r(end).time;
        
    else
        s.knobPosition = position;
        s.knobRotation = 0;
        s.knobButton = button;
        s.knobDown = 0;
        s.knobUp = 0;
        s.knobTime = GetSecs();
    end
end

function setBrightness(n)
    %set the brightness of the PowerMate. Input is an integer 0-255.
    %There are other reports to set pulse modes etc, but I don't know them.
    %and haven't been able to figure them out.
    PsychHID('SetReport', device, 2, 0, uint8([1 n]))
end

    function sync(n)
        %nothing needed
    end

end