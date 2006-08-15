function tryAll(varargin)
    %tries to execute every function given, ignoring errors until the end,
    %when the first encountered error is propagated.
    
    err = [];
    
    for i = varargin
        try
            i{:}();
        catch
            err(end+1) = lasterror;
        end
    end
    
    if ~isempty(err)
        rethrow(err(1));
    end
end