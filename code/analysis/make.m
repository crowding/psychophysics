function make(varargin)
%invokes make, and sets up an IP server to listen for and evalc matlab
%commands. It is a simple server, just evaluating strings and returning the
%strings produced. For each connection it reads up to the EOF, then writes
%the result back, then closes the connection. Befors startign the matlab
%server, a connection must be made on OUTPUT_PORT, which receives the
%output from "make".

%FIXME: needs some way to signal an error from matlab...

%environment variables we will pass to the command
%params.env = struct('MATLAB_HOST', 'localhost', 'MATLAB_PORT', '40983', 'NETCAT', '/sw/bin/nc6', 'OUTPUT_HOST', 'localhost', 'OUTPUT_PORT', '40984');

maker = backgroundcommand('command', sprintf('%s ', 'make', varargin{:}));
server = mlserver('initializer', maker.start, 'condition', maker.disp);

maker.setEnv(struct('MATLAB_HOST', 'localhost', 'MATLAB_PORT', num2str(server.getPort()), 'NETCAT', maker.getNetcat()));
server.setCondition(maker.disp);

server.run();

end