function i = switchscreen(varargin)
    %an initializer that switches the specified video port on the the
    %OceanMatrix video switchbox and switches back when done.
    params = struct ...
        ( 'videoOut', 1 ...
        , 'videoIn', 1 ...
        , 'port', 2 ...
        , 'portconfig', '9600,n,8,1' ...
        , 'machineNumber', 1 ...
        );
    
    params = namedargs(params, varargin{:});
    
    i = joinResource(openPort(params), verify(), switchScreen());
    
    function i = openPort(varargin)
        defaults = namedargs(varargin{:});
        i = @init;
        
        function [r, params] = init(params)
            params = namedargs(defaults, varargin{:});
            comm('open', params.port, params.portconfig);
            
            r = @release;
            function release()
                comm('close', params.port);
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
            
            if ~(issame(machine, [61, 0, 44]) & issame(version, [61, 1, 0]))
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
            
            if ~issame(response, [1, params.videoIn, params.videoOut])
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
        comm('purge', params.port);
        str = todevice + [command, input, output, params.machineNumber];
        comm('write', params.port, str);
        WaitSecs(0.1);
        resp = comm('read', params.port, 4);

        if length(resp) == 4
            resp = double(resp(:)') - [64 128 128 128];
            resp(end) = [];
        end
    end

end