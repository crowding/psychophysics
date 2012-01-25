function this = DiscreteStaircase(varargin)
    %Runs an N-up, N-down staircase on a discrete set of stimulus values.

    valueSet = linspace(0, 1, 11);
    currentIndex = 1;
    
    Nup = 1;
    Ndown = 1;
    useMomentum = 0;
    lastMove = 0;

    upCounter = 0;
    downCounter = 0;
    
    direction = 0;
    
    reversals = 0;
    
    criterion = TrialSuccessful();
    
    persistent init__;
    this = autoobject(varargin{:});
    
    function result(trial, result, valueUsed)
        
        %evaluate the criterion.
        value = ev(criterion, trial, result);
        
        if useMomentum
            if value ~= 0 && sign(value) == -sign(lastMove)
                upCounter = 0;
                downCounter = 0;
                disp ('CONTINUED STEP');
                if value < 0 && currentIndex < numel(valueSet)
                    currentIndex = currentIndex + 1;
                elseif value > 0 && currentIndex > 1
                    currentIndex = currentIndex - 1;
                end
                return
            else
                lastMove = 0;
            end
        end
        
        if value > 0                
                upCounter = 0;
                downCounter = downCounter + 1;

                if downCounter >= Ndown && currentIndex > 1
                    currentIndex = currentIndex - 1;
                    downCounter = 0;
                    disp ('step down');
                    lastMove = -1;
                    if (direction > 0)
                        reversals = reversals + 1;
                    end
                    direction = -1;
                end

        elseif value < 0 %count to a step UP

            downCounter = 0;
            upCounter = upCounter + 1;

            if upCounter >= Nup && currentIndex < numel(valueSet)
                currentIndex = currentIndex + 1;
                disp ('step up');
                lastMove = 1;
                upCounter = 0;
                if (direction > 0)
                    reversals = reversals + 1;
                end
            end

        end
    end

    function v = e(trial)
        v = valueSet(currentIndex);
    end

end