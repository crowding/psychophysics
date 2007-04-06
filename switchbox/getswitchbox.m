function i = getswitchbox(varargin)
    %an initializer that give you functions (params.switchin and params.switchout)
    %to switch 'in' and 'out' of the display.
    params = struct ...
        ( 'videoOut', 1 ...
        , 'videoIn', 1 ...
        , 'port', 2 ...
        , 'portconfig', '9600,n,8,1' ...
        , 'machineNumber', 1 ...
        );
    
    params = namedargs(params, varargin{:});
    
    i = joinResource(openPort(params), verify());
    
    function i = openPort(varargin)
        defaults = namedargs(varargin{:});
        i = @init;
        
        function [r, params] = init(params)
            params = namedargs(defaults, params);
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
            
            if ~(issame(machine, [61, 0, 44]) && issame(version, [61, 1, 0]))
                error('switchscreen:serial', 'no serial device, or wrong serial device');
            end
            prevIn = 2;
            getCurrent();
            in = 0;
            %functions to switch to/from the desired screen
            params.switchin = @switchin;
            params.switchout = @switchout;

            r = @noop;
            
            function switchin()
                if (in == 0)
                    getCurrent();
                end
                disp(sprintf('switching IN %d->%d', params.videoIn, params.videoOut));
                sw(params.videoIn, params.videoOut);
                in = 1;
            end
            
            function switchout()
                disp(sprintf('switching OUT %d->%d', prevIn, params.videoOut));
                sw(prevIn, params.videoOut);
                in = 0;
            end
            
            function sw(input, output)
                r = getresponse(params, 1, input, output);
                if ~issame(r, [1 input output])
                    error('getswitchbox:switchFailed', 'Could not switch video');
                end
            end
            
            function getCurrent()
                %what is the output currently set to?
                response = getresponse(params, 5, 0, params.videoOut);
                if (length(response) ~= 3) || response(1) ~= 5 || response(2) ~= 0
                    error('switchscreen:readFailed', 'could not read current setting');
                end
                prevIn = response(3);
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