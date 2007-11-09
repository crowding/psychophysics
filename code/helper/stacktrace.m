function stacktrace(errors)
%trace a passed-in error, or the last error of there was none. Can trace
%multiple errors given as an array.

%TODO: error causes, errors encountered while processing
%other errors; filtering of errors below a root

if ~exist('errors', 'var')
    errors = lasterror;
end

desktop = usejava('desktop');

output = {};
    function printf(varargin)
        output{end+1} = sprintf(varargin{:});
    end

arrayfun(@printStackTrace, errors);

disp(cat(2,output{:}));

    function printStackTrace(theErr, indent)
        if ~exist('indent', 'var')
            indent = '';
        end
        printErrorMessage(theErr);
        %disp([indent '??? ' theErr.identifier ': ' theErr.message]);
        arrayfun(@traceframe, theErr.stack);
        printf(' \n');

        function traceframe(frame)
            %print out a stack frame with a helpful link.
            %The error URL is undocumented as far as I know.
            if desktop
                printf('%s  In <a href="error:%s,%d,1">%s at %d</a>\n',...
                    indent, frame.file, frame.line, frame.name, frame.line);
            else
                printf('%s  In %s at %d\n', indent, frame.name, frame.line);
            end
            
            if isfield(frame, 'additional') && ~isempty(frame.additional)
                printf(' \n');
                printf('%s   which was caused by:\n', indent);
                for i = frame.additional(:)'
                    printStackTrace(i, [indent '    ']);
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
                    ,'File:\s*(.*)\s*Line:\s*(.*)\s*Column:\s*(\d*)'...
                    ,'<a href="error:$1,$2,$3">$0</a>');
            end
            message = regexprep(message, '[\r\n]+', ['$0' indent]);
            printf('%s??? %s : %s\n', indent, theErr.identifier, message);
        end
    end
end
