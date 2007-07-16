function this = DoubleSaccadeTrialGenerator(varargin)

    this = autoobject(varargin{:});
    
    function h = hasNext()
        h = 1;
    end

    function result(last, result)
        %interpret the last result, if it needs interpretation
    end

    function trial = next(params)
        trial = DoubleSaccadeTrial(); 
    end
end