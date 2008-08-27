function this = Identity(varargin)

    persistent init__;
    this = autoobject(varargin{:});
    
    function v = e(v)
        %identity function does nothing
    end 
end