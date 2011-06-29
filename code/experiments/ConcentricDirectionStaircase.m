function this = ConcentricDirectionStaircase(varargin)
    this = ConcentricDirectionConstant();
    this.caller=getversion(1);
    
    %we want two staircases, one a 1up/1down staircase on incongruent trials,
    %the other a 3up/1down staircase on the ambiguous trials.

    % get, for each eccentricity...
    %this.trials.replace('extra.r', 10);
    %this.trials.replace('extra.localDirection', 0)
    this.trials.reps = 20;
    
    parameters = {'extra.r'};
    values = cellfun(this.trials.get, parameters, 'UniformOutput', 0);
    
    %expand the grid of values with a PAIR OF staircases for each parameter
    %combination
    grid = expandGrid...
        ( values{:}...
          , { @() DiscreteStaircase('criterion', @incongruentCrowded, 'Nup', 1, 'Ndown', 1, 'valueSet', 1:30, 'currentIndex', 20) ...
          , @() DiscreteStaircase('criterion', @incongruentCrowded, 'Nup', 1, 'Ndown', 1, 'valueSet', 1:30, 'currentIndex', 8) ...
          } ...
        );
    
    %and instantiate all those staircases
    grid(:,end) = cellfun(@(x)x{1}(), grid(:,end), 'UniformOutput', 0);

    function crowded = incongruentCrowded(trial, result)
        crowded = 0;
        if result.success == 1
            gd = trial.property__('extra.globalDirection');
            if gd == -trial.property__('extra.localDirection')
                %note the logical reversal; the knob's positive rotation is
                %clockwise and the stimulus' positive rotation is CCW.
                if result.response == gd;
                    crowded = 1;
                elseif result.response == -gd;
                    crowded = -1;
                end
            end
        end
    end

    function crowded = counterphaseCrowded(trial, result)
        crowded = 0;
        if result.success == 1
            gd = trial.property__('extra.globalDirection');
            if trial.property__('extra.localDirection') == 0
                %note the logical reversal; the knob's positive rotation is
                %clockwise and the stimulus' positive rotation is CCW.
                if result.response == gd;
                    crowded = 1;
                elseif result.response == -gd;
                    crowded = -1;
                end
            end
        end
    end

    parameters = cat(2, parameters, 'extra.nTargets');
    cellfun(this.trials.remove, parameters);
    grid = num2cell(grid, 2);
    this.trials.addBefore('motion.process.t', parameters, grid);
    
    this.property__(varargin{:});
end
