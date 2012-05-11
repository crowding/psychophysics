function stacktrace(errors)
%Display a trace of the errors, similar to DBSTACK or the printout from
%WARNING.
%
%Present because there's no builtin way to print this information! Only the
%builtin methods that print then an exception reaches the top level....
%Which don't always work!

if ~exist('errors', 'var')
    
    % "last() method can only be called from command prompt."
    % WTF???????
    
    %if exist('MException', 'class') %new for 7.5...
    %    errors = MException.last();
    %else
    errors = lasterror;
    %end
end

desktop = usejava('desktop');

output = {};
    function printf(varargin)
        output{end+1} = sprintf(varargin{:});
    end

%arrayfun does not work on arrays of type MException.... or any other
%object. because arrays are a generic type, don't you know.
for ix = 1:numel(errors)
    if iscell(errors)
        printStackTrace(errors{ix});
    else
        printStackTrace(errors(ix));
    end
end
 
disp(cat(2,output{:}));

    function printStackTrace(theErr, indent)
        %forward compatible support for the new MException object in 7.5
        if isa(theErr, 'MException')
            theErr = mexception2errstruct(theErr);
        end

        if ~exist('indent', 'var')
            indent = '';
        end
        if ~(isfield(theErr, 'message'))
            %handle bare stacks too
            arrayfun(@traceframe, theErr);
            return;
        end
        printErrorMessage(theErr);
        %disp([indent '??? ' theErr.identifier ': ' theErr.message]);
        arrayfun(@traceframe, theErr.stack);
        printf(' \n');

        function traceframe(frame)
            %print out a stack frame with a helpful link.
            %The error URL is undocumented as far as I know.
            if desktop
                %some stacks give partial file names...
                printf('%s  In <a href="error:%s,%d,1">%s at %d</a>\n',...
                    indent, frame.file, frame.line, frame.name, frame.line);
            else
                printf('%s  In %s at %d\n', indent, frame.name, frame.line);
            end

            for field = {'additional', 'cause'}
                if isfield(frame, field{1}) && ~isempty(frame.(field{1}))
                    printf(' \n');
                    printf('%s   which was caused by:\n', indent);
                    for i = frame.(field{1})(:)'
                        printStackTrace(i, [indent '    ']);
                    end
                end
            end

            %a line of code...
            %dbtype(frame.file, num2str(frame.line));
        end

        function printErrorMessage(theErr)
            %some error messages are really parser messages, make it so I
            %can click in them
            message = theErr.message;
            if desktop
                message = regexprep(...
                    message...
                    ,'([^>])File:\s*(.*)\s*Line:\s*(.*)\s*Column:\s*(\d*)'...
                    ,'$1<a href="error:$2,$3,$4">$0</a>');
            end
            message = regexprep(message, '[\r\n]+', ['$0' indent]);
            printf('%s??? %s : %s\n', indent, theErr.identifier, message);
        end
    end
end
