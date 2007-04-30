function stacktrace(errors)
%trace a passed-in error, or the last error of there was none. Can trace
%multiple errors given as an array.

%TODO: error causes, errors encountered while processing
%other errors; filtering of errors below a root

if ~exist('errors', 'var')
    errors = lasterror;
end

arrayfun(@printStackTrace, errors);

    function printStackTrace(theErr, indent)
        if ~exist('indent', 'var')
            indent = '';
        end
        printErrorMessage(theErr);
        %disp([indent '??? ' theErr.identifier ': ' theErr.message]);
        arrayfun(@traceframe, theErr.stack);
        disp(' ');

        function traceframe(frame)
            %print out a stack frame with a helpful link.
            %The error URL is undocumented as far as I know.
            disp(sprintf('%s  In <a href="error:%s,%d,1">%s at %d</a>',...
                indent, frame.file, frame.line, frame.name, frame.line));
            
            if isfield(frame, 'additional') && ~isempty(frame.additional)
                disp(' ');
                disp(sprintf('%s   which was caused while handling an additional error:', indent));
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
            message = regexprep(...
                theErr.message...
                ,'File:\s*(.*)\s*Line:\s*(.*)\s*Column:\s*(\d*)'...
                ,'<a href="error:$1,$2,$3">$0</a>');
            message = regexprep(...
                theErr.message...
                ,'File:\s*(.*)\s*Line:\s*(.*)\s*Column:\s*(\d*)'...
                ,'<a href="error:$1,$2,$3">$0</a>');
            message = regexprep(message, '[\r\n]+', ['$0' indent]);
            disp([indent '??? ' theErr.identifier ': ' message]);
        end
    end
end