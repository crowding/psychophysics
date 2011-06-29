function this = MakeAConcentricDirectionStaircase(param, varargin)
    this = ConcentricDirectionConstant();
    this.caller=getversion(2);
    
    %synthesize up a concentric-direction-staircase experiment, which
    %varies one parameter across three values in comparison to the
    %others.

    % add in the temporal frequencies to test.
    try
        lv = this.trials.get(param);
        this.trials.replave(param, [lv*2/3 lv lv*3/2]);
    catch
        its_ = Genitive();
        substr = cat(2, its_.trials.base, tosubstruct(param));
        lv = subsref(this, substr);
        this.trials.addBefore('motion.process.t', param, [lv*2/3 lv lv*3/2]);
    end
    
    parameters = {'extra.r', param};
    values = cellfun(this.trials.get, parameters, 'UniformOutput', 0);
    
    %expand the grid of values staircases for each parameter
    %combination.
    grid = expandGrid...
        ( values{:}...
          , {@() DiscreteStaircase('criterion', @incongruentCrowded, 'Nup', 1, 'Ndown', 1, 'valueSet', 1:30, 'currentIndex', 12) } ...
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

    parameters = cat(2, parameters, 'extra.nTargets');
    cellfun(this.trials.remove, parameters);
    grid = num2cell(grid, 2);
    this.trials.addBefore('motion.process.t', parameters, grid);
    
    this.property__(varargin{:});
end