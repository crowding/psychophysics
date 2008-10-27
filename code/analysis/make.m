function make(varargin)
%invokes make, and sets up an IP server to listen for and evalc matlab
%commands. It is a simple server, just evaluating strings and returning the
%strings produced. For each connection it reads up to the EOF, then writes
%the result back, then closes the connection. Befors startign the matlab
%server, a connection must be made on OUTPUT_PORT, which receives the
%output from "make".

%FIXME: needs some way to signal an error form matlab...

%environment variables we will pass to the command
params.env = struct('MATLAB_HOST', 'localhost', 'MATLAB_PORT', '40983', 'NETCAT', '/sw/bin/nc6', 'OUTPUT_HOST', 'localhost', 'OUTPUT_PORT', '40984');
params.tcptimeout = 5;
params.commandargs = varargin;
params.pollinterval = 0.1;
params.command = 'make';

%for the matlab parts we read from a tcp socket; for the rest we readline
%from a fifo? no. We also write to a socket...

%While the check condition evaluates to true, matlab will continue to poll
%for connections.

require(params, @setupserver, @getconnection, @runserver);

    function [release, params] = setupserver(params)
        params.sockd = pnet('tcpsocket', params.env.MATLAB_PORT);
        if params.sockd == -1
            error('matlabserver:pnetSocketError', 'could not create socket (%d)', params.sockd);
        end

        release = @r;
        function r()
            pnet(params.sockd, 'close');
        end
    end

    function [release, params, next] = getconnection(params)
        %wait for a connection on the OUTPUT_PORT.
        params.insockd = pnet('tcpsocket', params.env.OUTPUT_PORT);
        if params.insockd == -1
            error('matlabserver:pnetSocketError', 'could not create socket (%d)', params.insockd);
        end
        
        release = @r;
        next = @backgroundcommand;
        function r()
            pnet(params.insockd, 'close');
        end
    end

    function [release, params, next] = backgroundcommand(params)
        %the command will be preceded by the environment
        initstring = join ...
            ( ' ' ...
            , cellfun ...
                ( @(a, b) [a '=' b] ...
                , fieldnames(params.env) ...
                , struct2cell(params.env) ...
                , 'UniformOutput', 0 ...
                )...
            );
        
        %FIXME: Sigh. the netcat process doesn't stop here even with -w 1.
        %Trying netcat6...
        commandstring = sprintf...
            ('%s %s %s 2>&1 | %s -q0 %s %s & echo $!'...
            , initstring...
            , params.command...
            , sprintf('%s ', params.commandargs{:}) ...
            , params.env.NETCAT ...
            , params.env.OUTPUT_HOST ...
            , params.env.OUTPUT_PORT ...
            );
        
        [status, pid] = system(commandstring);
        if status ~= 0
            error('make:commandError','could not execute command "%s"; returned %d, "%s"', params.command, status, pid);
        end
        pid = strcat(pid) %strip trailing whitespace;

        next = @waitconnection;
        release = @r;
        function r()
            %test if the process is still running. If so, kill it.
            [status, t] = system(sprintf('ps -p %s', pid));
            if ~isempty(strfind(t, pid))
                warning('make:killingSubprocess', 'killing process %s\n', pid);
                system(sprintf('kill %s', pid));
            end
        end

    end

    function [release, params] = waitconnection(params)
        pnet(params.insockd, 'setreadtimeout', params.tcptimeout);
        params.inconn = pnet(params.insockd, 'tcplisten');
        if (params.inconn < 0)
            error('make:noConnection', 'failed to receive TCP connection to make output');
        end
        params.checkcondition = @showoutput;
        
        release = @r;
        function cont = showoutput()
            f = pnet(params.inconn, 'read', 'noblock');
            if numel(f) > 0
                fprintf('%s', f);
            end
            %check still connected -- returns 0 on disconnect
            cont = pnet(params.inconn, 'status');
        end
        
        function r()
            pnet(params.inconn, 'close');
        end
    end

    function runserver(params)
        while(1)
            con = pnet(params.sockd, 'tcplisten', 'noblock');
            while con ~= -1
                pnet(con, 'setreadtimeout', params.tcptimeout);
                try
                    %service the handler
                    %The protocol is to give a set of matlab commands, and
                    %then two newlines finishes a command. I evaluate and
                    %write back the result, then close.
                    %If this were a proper daemon it would fork and leave
                    %the parent free to accept other connections; but it is
                    %not a proper daemon.
                    
                    command = '';
                    while(1)
                        line = pnet(con, 'readline');
                        if isempty(line)
                            break
                        end
                        command = [command line 10];
                    end
                    
                    if ~isempty(command)
                        fprintf('%s\n', command);
                        response = '';
                        eval(command); %assign to response in the command if you want a response
                        %I want to throw if there is an error.
                        %TODO: find a way to get the error back to the
                        %caller?
                        pnet(con, 'write', response);
                    end
                catch
                    e = lasterror();
                    try
                        pnet(con, 'close');
                    catch
                        e = adderror(lasterror, e);
                    end
                    rethrow(e);
                end
                
                pnet(con, 'close');

                con = pnet(params.sockd, 'tcplisten', 'noblock');
            end
            if ~params.checkcondition()
                break;
            end
            pause(params.pollinterval);
        end
    end

end