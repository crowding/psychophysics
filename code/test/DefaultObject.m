function this = DefaultObject(varargin)

    persistent init__;
    
    prop = 4;

    this = autoobject(varargin{:});
end