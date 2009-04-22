function this = RandStream(varargin)

    seed = rand('twister');
    persistent init__;
    this = autoobject(varargin{:});
    
    function varargout = e(varargin)
        tmp = rand('twister');
        try
            rand('twister', seed);
            [varargout{1:nargout}] = rand(varargin{:});
            seed = rand('twister');
        catch
            rand('twister', tmp);
            rethrow(lasterror);
        end
        rand('twister', tmp);
    end
end