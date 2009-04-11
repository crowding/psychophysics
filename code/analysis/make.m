function make(varargin)
%invokes make, and sets up an IP server to listen for and evalc matlab
%commands. It is a simple server, just evaluating strings and returning the
%strings produced. For each connection it reads up to the EOF, then writes
%the result back, then closes the connection. Befors startign the matlab
%server, a connection must be made on OUTPUT_PORT, which receives the
%output from "make".

%FIXME: needs some way to signal an error from matlab...

%environment variables we will pass to the command

    maker = backgroundcommand('command', sprintf('%s ', 'make 2>&1', varargin{:}));
    server = mlserver('initializer', maker.start, 'condition', maker.disp);

    maker.setEnv(struct('MATLAB_HOST', 'localhost', 'MATLAB_PORT', num2str(server.getPort()), 'NETCAT', maker.getNetcat()));
    server.setCondition(maker.disp);

    require(@protect_path, server.run);

    function [release, params] = protect_path(params)
        d = pwd;
        p = path;
        
        release = @r;
        function r()
            cd(d);
            path(p);
        end
    end

end