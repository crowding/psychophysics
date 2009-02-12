function i = switchscreen(varargin)
%An initializer that switches the specified video port on the the
%OceanMatrix video switchbox and switches back when done. Takes these 
%named options (defaults in parentheses):
%         'videoOut (1) The output port.
%         'videoIn', (1) The input port.
%         'immediate' (0) Switch immediately instead of making an initializer.
%         'port', (2) Which serial port.
%         'portconfig', ('9600,n,8,1') The serial port configuration.
%         'machineNumber' (1) The address of the OMX.

    params = struct ...
        ( 'videoOut', 1 ...
        , 'videoIn', 1 ...
        , 'immediate', 0 ...
        , 'port', 2 ...
        , 'portconfig', '9600,n,8,1' ...
        , 'machineNumber', 1 ...
        );
    
    params = namedargs(params, varargin{:});
    
    if(params.immediate)
        require(openPort(params), verify(), switchScreen());
        return;
    end
    
    i = joinResource(openPort(params), verify(), switchScreen());
    
    function i = openPort(varargin)
        defaults = namedargs(varargin{:});
        i = @init;
        
        function [r, params] = init(params)
            params = namedargs(defaults, varargin{:});
            SerialComm('open', params.port, params.portconfig);
            r = @release;
            function release()
                SerialComm('purge', params.port);
                SerialComm('close', params.port);
            end
        end
    end

    function i = verify(varargin)
        defaults = namedargs(varargin{:});
        i = @init;
    
        function [r, params] = init(params)
            params = namedargs(defaults, params);
            
            machine = getresponse(params, 61, 1, 0);
            version = getresponse(params, 61, 3, 0);
            
            if ~(isequalwithequalnans(machine, [61, 0, 44]) & isequalwithequalnans(version, [61, 1, 0]))
                error('switchscreen:serial', 'no serial device, or wrong serial device');
            end

            r = @noop;
        end
    end

    function i = switchScreen(varargin)
        defaults = namedargs(varargin{:});
        i = @init;
        
        function [r, params] = init(params)
            params = namedargs(defaults, params);
            
            response = getresponse(params, 5, 0, params.videoOut);

            if (length(response) ~= 3) || response(1) ~= 5 || response(2) ~= 0
                error('switchscreen:readFailed', 'could not read current setting');
            end
            
            prevOutput = params.videoOut;
            prevInput = response(3);
            
            response = getresponse(params, 1, params.videoIn, params.videoOut); 
            
            if ~isequal(response, [1, params.videoIn, params.videoOut])
                release();
                error('switchscreen:switchFailed', 'failed to switch screen');
            end
            
            r = @release;
            
            function release
                response = getresponse(params, 1, prevInput, prevOutput);
                if ~issame(response, [1 prevInput prevOutput])
                    error('switchscreen:switchFailed', 'failed to revert screen setting');
                end
            end
        end
    end

    function resp = getresponse(params, command, input, output)
        todevice = hex2dec(['00';'80';'80';'80'])';
        SerialComm('purge', params.port);
        str = todevice + [command, input, output, params.machineNumber];
        SerialComm('write', params.port, str);
        pause(0.1);
        resp = [];
        s = GetSecs();
        while (GetSecs - s) < 0.2 && numel(resp) < 4
            resp = [resp SerialComm('read', params.port, 4 - numel(resp))]; %#ok
        end
        
        if length(resp) == 4
            resp = double(resp(:)') - [64 128 128 128];
            resp(end) = [];
        else
            noop();
        end
    end

end
