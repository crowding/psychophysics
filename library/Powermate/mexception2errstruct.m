function err = mexception2errstruct(theErr)
    %convert an MException (new thing in matlab 7.5) back into an error
    %structure (which supports causes associated with stack levels, at
    %least my version with stacktrace.)
    %
    %see also STACKTRACE.
    
    err = struct('identifier', theErr.identifier, 'message', theErr.message, 'stack', theErr.stack);
    for i = 1:numel(theErr.cause)
        err = adderror(err, theErr.cause{i});
    end
end