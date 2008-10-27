function [release, params, next] = gunziplines(params)
defaults = struct('gzipfile', '', 'chunksize', 512, 'delimiter', sprintf('\n'));
%returns a 'readline' function handle in the output struct that reads from
%a compressed file one line at a time until it returns -1.
%required param input is a 'gzipfile'.

%TODO: This would work better with netcat perhaps?

f = joinResource( defaults ...
    , @mkfifo, @gunzip, @openfifo, @mkreadline);

[release, params, next] = f(params);

    function [release, params] = mkfifo(params)
        params.fifoname = tempname();
        system(['mkfifo ' params.fifoname]);
        release = @r;

        function r()
            delete(params.fifoname);
        end
    end

    function [release, params] = gunzip(params)
        %run and capture the process ID
        [status, pid] = system(sprintf('gunzip -c "%s" > "%s" & echo $!', params.gzipfile, params.fifoname));
        pid = strcat(pid); %strip trailing whitespace;

        release = @r;
        function r()
            %test if the process is still running. If so, kill it.
            [status, t] = system(sprintf('ps -p %s', pid));
            if ~isempty(strfind(t, pid))
                fprintf('killing process %s\n', pid);
                system(sprintf('kill %s', pid));
            end
        end
    end

    function [release, params] = openfifo(params)
        params.fid = fopen(params.fifoname);

        release = @r;
        function r()
            fclose(params.fid);
        end
    end

    function [release, params] = mkreadline(params)
        buffer = '';

        params.readline = @rl;
        release = @noop;

        function resp = rl
            ix = find(buffer == params.delimiter, 1, 'first');
            while isempty(ix)
                %readlines don't work on a pipe. For whatever reason. So we
                %implement our own readilne.
                [chunk, count] = fread(params.fid, params.chunksize);
                if count == 0
                    break;
                end
                buffer = [buffer; chunk];
                ix = find(buffer == params.delimiter, 1, 'first');
            end
            
            if isempty(ix)
                if isempty(buffer)
                    resp = -1;
                else
                    resp = buffer;
                    buffer = [];
                end
            else
                resp = buffer(1:ix-1)';
                buffer(1:ix-1 + numel(params.delimiter)) = [];
            end
        end
    end
end