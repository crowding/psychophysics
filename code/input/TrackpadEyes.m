function TrackpadEyes(varargin)
    %Pretends to be an eye input sampled at 1 khz (interpolating position
    %samples from the trackpad.)
    
    

    device = [];
    options = struct('secs', 0, 'input', 0);
    
    function d = discover()
        device = discover()
    end
    
    function [release, params] = init
        if isempty(device)
            d = discover();
        end
        function stop
            PsychHID('ReceiveReportsStop', d)
        end
    end

    function [release, params] = begin
        
    end
    
    function discover
    end

    function e = input(e)
        PsychHID('ReceiveEvents', device, options);
        PsychHID('GiveMeEvents', device)
        
    end

end
