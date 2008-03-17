function this = DiscreteStaircase(varargin)
    %Runs an N-up, N-down staircase on a discrete set of stimulus values.

    valueSet = linspace(0, 1, 11);
    currentIndex = 1;
    
    Nup = 1;
    Ndown = 1;

    upCounter = 0;
    downCounter = 0;
    
    direction = 0;
    
    reversals = 0;
    
    persistent init__;
    this = autoobject(varargin{:});
    
    function result(trial, result)
        if isfield(result, 'success') %step down
            if (~isnan(result.success) && result.success) %step DOWN
                
                upCounter = 0;
                downCounter = downCounter + 1;

                if downCounter >= Ndown && currentIndex > 1
                    currentIndex = currentIndex - 1;
                    downCounter = 0;
                    disp ('step down');
                    if (direction > 0)
                        reversals = reversals + 1;
                    end
                    direction = -1;
                end

            elseif ~isnan(result.success) %count to a step UP
                
                downCounter = 0;
                upCounter = upCounter + 1;

                if upCounter >= Nup && currentIndex < numel(valueSet)
                    currentIndex = currentIndex + 1;
                    disp ('step up');
                    upCounter = 0;
                    if (direction > 0)
                        reversals = reversals + 1;
                    end
                end

            end
        end
    end

    function v = e(trial)
        v = valueSet(currentIndex);
    end

end