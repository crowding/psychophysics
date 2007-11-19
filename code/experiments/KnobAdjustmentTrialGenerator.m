function this = KnobAdjustmentTrialGenerator(varargin)
    %Logic/sequencing for doing adjustments.
    
    base = KnobAdjustmentTrial();
    running = 1;
    
    adjustmentDistance = 0.025;
    
    index = 1;
    
    initialBarPhaseDisplacement = 0;
    initialBarOnset = 0.5;
    velocity = [5];
    dx = 1;
    initialPhase = 0;
    
    finalBarPhaseDisplacement = [];
    adjustments = {};
    
    isi = 0;
    
    nextOnset_ = 0;
    
    persistent init__;
    this = autoobject(varargin{:});
    
    function has = hasNext();
        has = running;
    end

    function trial = next(params);
        trial = base;
        if numel(adjustments) < index
            trial.setBarPhaseDisplacement(initialBarPhaseDisplacement(index));
            trial.setBarOnset(initialBarOnset(index));
            trial.setStartTime(nextOnset_);
            
            m = trial.getMotion();
            phi = m.getPhase();
            phi(1) = initialPhase(index);
            r = m.getRadius();
            p = trial.getPatch();
            
            m.setPhase(phi);
            m.setDphase(dx(index) / r(1));
            m.setAngle(90 + 180/pi*phi);
            p.velocity = velocity(index);
            trial.setPatch(p);
            adjustments(index) = {[]};
            
            base = trial;
            
            if mod(index, 10) == 1
                trial = MessageTrial('message', sprintf('Trial %d/%d.\n Move the knob to adjust the position of the flash.\n Press to continue', index, numel(initialBarPhaseDisplacement)));
            end
        end
    end

    function result(trial, result)
        if isfield(result, 'endTime')
            nextOnset_ = result.endTime + isi;
        end
        
        if isfield(result, 'abort') && result.abort
            running = 0;
        end
        
        if result.success && isfield(result, 'direction')
            if result.direction == 0
                finalBarPhaseDisplacement(index) = trial.getBarPhaseDisplacement();
                index = index + 1;
                if index > numel(initialBarPhaseDisplacement)
                    running = 0; %yay we completed the experiment
                end
            else
                %adjust the bar position
                phi = trial.getBarPhaseDisplacement();
                r = trial.getMotion();
                r = r.getRadius();
                r = r(1);
                phi = phi + result.direction * adjustmentDistance / r;
                trial.setBarPhaseDisplacement(phi);
                
                %store the adjustment
                %record the adjustment
                if numel(adjustments) < index;
                    adjustments{index} = [];
                end
                adjustments{index}(end+1) = trial.getBarPhaseDisplacement();

                base = trial;
            end
        end
    end
end