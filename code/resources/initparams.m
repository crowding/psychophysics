function initializer = initparams(varargin)
%an initializer used to provide the initial params for a require() call

initializer = currynamedargs(@init, varargin{:});

    function [release, params] = init(params)
        release = @noop;
    end

end