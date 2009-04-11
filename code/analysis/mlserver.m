function this = mlserver(varargin)
%This object constructs a matlab process server running on the
%specified host and port. The server waits for a TCP connection, and
%continues to poll until a condition evaluates to false.
%
%On connecting, the client writes a series of matlab commands, ending
%with two newlines. The server then evaluates the commands in the base
%workspace. Any response is written back to the output in the manner of
%EVALC and the connection is closed. Commands are evaluated in the base
%workspace.

port = 40983;
condition = @(x)true;
initializer = @noinit; %this is an extra initializer to run after you've set up the server but before you've run the command...
pollinterval = 0.1;
readtimeout = 5;

persistent init__;
this = autoobject(varargin{:});

    function run()
        require(@startserver_, @runserver_);
    end

    function [release, params, next] = startserver_(params)
        %create a socket...
        params.sockd = pnet('tcpsocket', port);
        if params.sockd == -1
            error('matlabserver:pnetSocketError', 'could not create socket (%d)', params.sockd);
        end

        release = @r;
        next = initializer;
        function r()
            pnet(params.sockd, 'close');
        end
    end

    function params = runserver_(params)
        %check for connections on the socket...
        while(condition())
            params = require(params, @listen_, @serve_);
            if params.con == -1
                pause(pollinterval);
            end
        end
    end

    function [release, params] = listen_(params)
        params.con = pnet(params.sockd, 'tcplisten', 'noblock');

        release = @close;
        function close()
            if params.con ~= -1
                pnet(params.con, 'close');
            end
        end
    end

    function params = serve_(params)
        if params.con ~= -1
            pnet(params.con, 'setreadtimeout', readtimeout);
            %service the handler
            %The protocol is to give a set of matlab commands, and
            %then two newlines finishes a command. I evaluate and
            %write back the result, then close.
            %If this were a proper daemon it would fork and leave
            %the parent free to accept other connections; but it is
            %not a proper daemon.
            command = '';
            while(1)
                %read to a line or what?
                line = pnet(params.con, 'readline');
                if isempty(line)
                    break
                end
                command = [command line 10]; %10 is newline.
                
                % fugging hack to deal with broken netcat/pnet interaction
                % (keep nc from dropping the connection early, or pnet from
                % thinking it has, not sure which.) 
                next = pnet(params.con, 'read', 1, 'view', 'noblock');
                if next == 10
                    break;
                end
            end

            if ~isempty(command)
                fprintf('%s\n', command);
                evalin('base', 'clear(''ans'')');
                assignin('base', 'command__', command);
                s = evalin('base', 'evalc(command__)');
                %write back the response...
                pnet(params.con, 'write', s);
            end

        end
    end
end