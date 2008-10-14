function this = ResultSuccessful(varargin)
    %evaluatable object that returns 1 of trial was successful, -1 if not,
    %and 0 if other.
    
    persistent init__;
    this = autoobject(varargin{:});
    
    function v = e(result)
        if isfield(result, 'success') && ~isnan(result.success)
            if result.success
                v = 1;
            else
                v = 0;
            end
        else
            v = 0;
        end
    end
end