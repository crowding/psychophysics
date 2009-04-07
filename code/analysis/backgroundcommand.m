function this = backgroundcommand(varargin)

%starts up a background command by piping its output through
%a network pipe (requiring pnet.mex). After requiring 'start', you can then
%use the 'read' method to communicate with the background process.
%The 'env' struct will be used as the environment to the command.
%'host' and 'port' should point to a host and port on this 

host = 'localhost';
port = 40984;
errport = 40985;
timeout = 10;
netcat = [];
env = struct();
command = 'yes';

persistent init__;
this = autoobject(varargin{:});
findnetcat_();

    function tail()
        %this merely runs the command...
        require(@start, @cat);
        function cat()
            status = 1;
            while(status)
                [f, status] = read();
                if numel(f) > 0
                    fprintf('%s', f);
                end
            end
        end
    end

    function status = disp()
        [f, status] = read();
    end

    function [release, params, next] = start(params)
        release = @noop;
        next = @findnetcat_;
    end
        
    function [release, params, next] = findnetcat_(params)
        if isempty(netcat)
            [a, s] = system('which nc');
            [a6, s6] = system('which nc6');
            s6 = strcat(s6); %strip trailing whitespace
            s = strcat(s);

            if exist(s, 'file')
                netcat = s;
            elseif exist(s6, 'file');
                netcat = [s6 ' -q -:0'];
            elseif exist('/usr/bin/nc', 'file');
                netcat = '/usr/bin/nc';
            elseif exist('/sw/bin/nc6', 'file');
                netcat = '/sw/bin/nc6 -q -:0';
            elseif exist('/sw/bin/nc', 'file');
                netcat = '/sw/bin/nc';
            else
                error('backgroundcommand:netcat', 'netcat not found!');
            end

        end
        release = @noop;
        next = @listen_;
    end

    function [release, params, next] = listen_(params)
        %wait for a connection on the OUTPUT_PORT.
        params.insockd = pnet('tcpsocket', port);
        if params.insockd == -1
            error('matlabserver:pnetSocketError', 'could not create socket (%d)', params.insockd);
        end

        release = @r;
        next = @backgroundcommand_;
        function r()
            pnet(params.insockd, 'close');
        end
    end

    function [release, params, next] = backgroundcommand_(params)
        %the command will be preceded by the environment
        initstring = join ...
            ( ' ' ...
            , cellfun ...
            ( @(a, b) [a '=' b] ...
            , fieldnames(env) ...
            , struct2cell(env) ...
            , 'UniformOutput', 0 ...
            )...
            );
        
        %to clean up, we capture the command pid and the netcat pid.
        commandstring = sprintf...
            ('%s %s 2>&1 | %s %s %d & jobs -p;echo $!'...
            , initstring...
            , command...
            , netcat ...
            , host ...
            , port ...
            );

        [status, pids] = system(commandstring);
        if status ~= 0
            error('make:commandError','could not execute command "%s"; returned %d, "%s"', params.command, status, pid);
        end
        pids = sscanf(pids, '%d');
        
        release = @r;
        function r()
            %test if the processes are still running. If so, kill them.
            for i = pids(:)'
                pid = num2str(i);
                [status, t] = system(sprintf('ps -p %s', pid));
                if ~isempty(strfind(t, pid))
                    warning('backgroundcommand:killingSubprocess', 'killing process %s, %s\n', pid, t);
                    system(sprintf('kill %s', pid));
                end
            end
        end
        
        next = @connect_;
    end

    con_ = [];
    function [release, params] = connect_(params)
        pnet(params.insockd, 'setreadtimeout', timeout);
        con_ = pnet(params.insockd, 'tcplisten', 'noblock');
        if con_ == -1
            error('backgroundcommand:noConnection', 'could not establish connection');
        end
        release = @r;
        function r()
            con_ = [];
        end
    end

    function [what, status] = read()
        what = pnet(con_, 'read', 'noblock');
        status = pnet(con_, 'status');
    end
end