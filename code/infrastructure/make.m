function make(varargin)

% Runs MAKE from within matlab, while listening on a named pipe for 
% commands to evaluate. Evaluates all the commands, then waits until the
% pipe is closed.
%
% This is sort of convoluted...

require(mkfifos, runbackground('args', varargin), @processfifo);
%also need a mklockfile for synching the make process with the matlab
%process

    function initializer = mkfifo(varargin)
        %Initializer.
        %
        %Creates a temporary named pipe (fifo).
        %Default name for the fifo is given by 'tempname'
        %parameters:
        %   'fifo' (in/out) the file
        
        defaults = struct('fifo', [tempname '.fifo'], 'matlabout', [tempname]);
        initializer = currynamedargs(@init, defaults, varargin{:});

        function [release, params] = init(params)
            s = system(['mkfifo -m o-rw,g-rw ' params.fifo]);

            if s
                error('make:mkfifo', 'return value %d from mkfifo', s);
            end

            release = @r;

            function r
                if exist(params.fifo, 'file')
                    delete(params.fifo);
                end
            end
        end
    end


    function initializer = mkfifos(varargin)
        %Initializer factory.
        %Creates two named fifos, one on and one out.
        
        %parameters:
        %   'fifoin' (in/out) the file
        %   'fifoout' the fifo out
        params = namedargs(varargin{:});
        
        initializer = joinResource(...
            rename(mkfifo(params), 'fifo', 'fifoin'),... 
            rename(mkfifo, 'fifo', 'fifoout') );
        
        function initializer = rename(orig_init, orig, renamed)
            %renames one of the input/output variables produced by an
            %initializer.
            initializer = @rinit;
            
            function [release, params] = rinit(params)
                if isfield(params, rename)
                    [release, params] = orig_init(namedargs(params, orig, params.(rename)));
                else
                    [release, params] = orig_init(params);
                end
                
                if isfield(params, orig)
                    params.(renamed) = params.(orig);
                    params = rmfield(params, orig);
                end
            end
        end
    end


    function initializer = runbackground(varargin)
        %Initializer.
        %
        %runs a command in the background, capturing its process ID.
        %takes an 'env' parameter which is a structure; its fields are
        %injected into the environment of the command.
        %
        %parameters:
        %   'env' (in) a struct giving environment variables to pass
        %   'pid' (out) the process ID of the process that is started.
        defaults = struct('command', ['make'], 'env', struct(), 'args', {{}});
        initializer = currynamedargs(@init, defaults, varargin{:});
        
        function [releaser, params] = init(params)
            params = namedargs('env', struct('MATLAB_FIFO', params.fifoin, 'MAKE_FIFO', params.fifoout, 'MATLAB_OUT', params.matlabout), params);
            %'env' is a structure; convert it into initializer strings
            initstring = ...
                join ...
                    ( ' ' ...
                    , cellfun ...
                        ( @(a, b) [a '=' b] ...
                        , fieldnames(params.env) ...
                        , struct2cell(params.env) ...
                        , 'UniformOutput', 0 ) );
           
            %we want to execute the command and capture the process
            %ID it is executing under, redirecting the command's output to
            %the console? (TODO: make it appear in the matlab window
            %somehow.)
            
            %"rm fifo > fifo" is a trick to open the fifo, delete it, and then
            %close it, in that order (thus properly hanging up on the
            %waiting matlab thread in processfifo, below)
            
            %Note that it depends on the releaser to break the fifo
            %(otherwise it is left hanging).
            
            %This command runs make in the beckground with the
            %proper environment, piping output to the console, and outputs
            %the process ID.
            commandstring = sprintf...
                ('bash --login -c "{ %s %s; rm %s > %s; } >/dev/console 2>&1 & echo $!"'...
                , initstring...
                , [params.command join(' ',{'',params.args{:}})]...
                , params.fifoin...
                , params.fifoin);

            %params.pid is the bash subshell created by the braces in the
            %above command
            [status, params.pid] = system(commandstring);
            params.pid = strcat(params.pid); %strip trailing whitespace;

            if status
                error('make:runbackground', 'nonzero exit status %d from shell', status);
            end
            
            releaser = @release;
                    
            function release
                %if the process is still running, end it
                [s, t] = system(sprintf('ps -p %s', params.pid));
                if strfind(t, params.pid)
                    s = system(['kill ' params.pid]);
                end
                
                if s
                    error('make:runbackground', 'status %d stopping background job');
                end
            end
        end
    end

    function processfifo(varargin)
        %reads lines from a fifo and evaluates them, until the process
        %denoted by a certain PID is ended.
        %
        %parameters:
        %
        %'fifoout' a file descriptor for the fifo
        %'pid' the background process
        
        %The notion of communicating through pipes is crippled by MATLAB not
        %supporting non-blocking reads or the select() operation; this 
        %causes a problem because it's hard to find out if the subprocess
        %is done when we are using blocking reads. our
        %strategy is to have the child process open delete, and then close
        %the fifo (causing our read to fail)
        
        %the fifo should be deleted upon completion of the command;
        params = namedargs(varargin{:});
        
        while exist(params.fifoin, 'file') 
            %read something from the fifo and execute it
            %we use 'cat' to read the file, because MATLAB itself can't
            %work with fifos for some stupid reason. fopen() never returns.
            
            %this depends on the file being closed between every command
            %invocation?
            
            [s, text] = system(sprintf('cat %s', params.fifoin));
            if (s == -1)
                error('make:processfifo', 'status %d from cat', s);
            end
                      
            %evaluate each line as a command, 
            cmds = splitstr(sprintf('\n'), text);
            cellfun(@disp, cmds);
            output = cellfun(@evalc, cmds, 'UniformOutput', 0);
            
            %print the output to a temp output file...
            f = fopen(params.matlabout, 'w+');
            fprintf('%s\n', output{:});
            fclose(f);
            
            if exist(params.fifoin, 'file')
                %MATLAB signals back when its side is done by opening and
                %closing this fifo.
                [s, text] = system(sprintf('echo > %s', params.fifoout));
            end
        end
    end
end