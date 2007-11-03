function this = Powermate(varargin)
%function this = Powermate(handlers, '');
%Event-handler Object for communicating with a Griffin Powermate controller.
handlers = {};
device = [];

varargin = assignments(varargin, 'handlers');
this = autoobject(varargin{:});

function d = discover()
    d = PsychHID('devices');
    d = d(([d.vendorID] == 1917) & ([d.productID] == 1040));
    if isempty(device) && ~isempty(d)
        device = d(1).index;
    end
    d = [d.index];
end

function [release, params] = init(params)
    handlers = interface(struct('setLog', {}, 'check', {}, 'init', {}), handlers);
    %scan for the PowerMate -- vendorID 1917, productID 1040
    if isempty(device)
        discover();
        if isempty(device)
            error('powermate:noDeviceFound', 'No device found.');
        end
    end
    
    for i = handlers(:)'
        i.setLog(params.log);
    end
    
    cont = joinResource(handlers.init);
    [release, params] = cont(params);
end

position = 0;
button_ = 0;

function s = check(s)
    %s - the structure which begins by containing drawing information (what
    %refresh the next refresh is, and when it is scheduled.)
    %Adds the following fields:
    %knobPosition -- integrated position of hte powermate
    %knobRotation -- the time the 
    %knobButton -- the final state of hte button
    %knobDown -- how many times the button was pressed
    %knobUp -- how many tmies the button was released
    %knobTime -- the time the kob's state was known
    PsychHID('ReceiveReports', device);
    r = PsychHID('GiveMeReports', device);
    
    if ~isempty(r)
        data = double(cat(1, r.report));
        
        %signed int8
        button = data(:,1);
        transitions = diff([button_; button]);
        button_ = button(end);
        
        %it will give values up to 8/down to -8, which is the same bit
        %pattern at both ends, si I have to use direction to get the sign

        shifts = data(:,2);
        shifts(shifts >= 128) = shifts(shifts>=128) - 256;
        shift = sum(shifts);
        
        position = position + shift;
        s.knobPosition = position;
        s.knobRotation = shift;
        s.knobButton = double(button(end));
        s.knobDown = sum(transitions > 0);
        s.knobUp = sum(transitions < 0);
        s.knobTime = r(end).time;
    else
        s.knobPosition = position;
        s.knobRotation = 0;
        s.knobButton = button_;
        s.knobDown = 0;
        s.knobUp = 0;
        s.knobTime = GetSecs();
    end
end

function setBrightness(n)
    %set the brightness of the PowerMate. Input is an integer 0-255.
    PsychHID('SetReport', device_, 2, 0, uint8([1 128]))
end

end