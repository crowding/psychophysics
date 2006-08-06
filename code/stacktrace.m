function stacktrace(theErr)
%trace a passed-in error, or the last error of there was none.

%TODO: error causes, multiple errors, errors encountered while processing
%other errors; filtering of errors below a root

if ~exist('theErr', 'var')
    theErr = lasterror;
end

disp(['??? ' theErr.identifier ': ' theErr.message]);
arrayfun(@traceframe, theErr.stack);
disp('');

    function traceframe(frame)
        %print out a stack frame with a helpful link.
        %The error URL is undocumented as far as I know.
        disp(sprintf('  In <a href="error:%s,%d,1">%s at %d</a>',...
            frame.file, frame.line, frame.name, frame.line));
        %a line of code...
        %dbtype(frame.file, num2str(frame.line));
    end
end