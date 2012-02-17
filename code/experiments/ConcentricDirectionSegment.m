function this = ConcentricDirectionSegment(varargin)
    this = ConcentricDirectionConstant();
    this.caller=getversion(1);
    
    %now, rather than a cross up of all target numbers and all target
    %densities, we want to select them from a grid of values that work
    
    this.trials.reps = 1;
    this.trials.base.extra.flankerCarriesLocal = 0;
    
    %we have another script for generating some configurations...
    configurations = occlusiongen();
    
    this.trials.base.extra.r = 20/3;
    this.trials.addBefore...
        ( 'extra.nTargets' ...
        , {'extra.nTargets',                                      'extra.nVisibleTargets', 'motion.process.n',    'extra.min_extent',        'extra.max_extent',        'extra.min_distance'} ...
        , num2cell(num2cell([round(2*pi./configurations.spacing), configurations.nTargets, configurations.nsteps, configurations.min_extent, configurations.max_extent, configurations.min_distance]'), 1));
    this.trials.addBefore('extra.nTargets', 'extra.side', {'left', 'right', 'left', 'right', 'left', 'right'}, 1); %side is blocked
    
    this.trials.base.useOccluders = 0;
    
    this.trials.addBefore('extra.localDirection', {'extra.flankerPhase', 'extra.flankerAngle', 'extra.phase'}, @occluder);
    function out = occluder(b)
        extra = b.extra;
        %pick a random extent between the min and max extent
        movingExtent = 2*pi/extra.nTargets * (extra.nVisibleTargets-1);
        %extent = rand() * (extra.max_extent - extra.min_extent) + extra.min_extent;
        %whoops, if I use different values of dx, then the "extent" goes out the
        %window, and I really want to guarantee min spacing, is what.
        extent = movingExtent + 2*extra.min_distance;
        traversed = extra.globalVScalar * b.motion.process.dt * b.motion.process.n;
                
        switch(extra.side)
            case 'left'
                flankPhase = pi + [-0.5 0.5]*extent;
            case 'right'
                flankPhase = [-0.5 0.5]*extent;
            case 'top'
                flankPhase = 3*pi/2 + [-0.5 0.5]*extent;
            case 'bottom'
                flankPhase = pi/2 + [-0.5 0.5]*extent;
            otherwise
                error();                
        end
        (extent - movingExtent - traversed - 2*extra.min_distance)
        switch(extra.globalDirection)
            case -1
                phase = flankPhase(2) - extra.min_distance - movingExtent - rand() * (extent - movingExtent - traversed - 2*extra.min_distance);
            case 1
                phase = flankPhase(1) + extra.min_distance + rand() * (extent - movingExtent - traversed - 2*extra.min_distance);
        end
        
        out = {flankPhase, flankPhase * 180/pi + 90, phase};
    end

    this.trials.add('extra.useFlankers', @configureFlankers);
    function out = configureFlankers(b)
        m = b.getMotion();
        p = m.getProcess();
        ex = b.getExtra();
        
        out = 1;
        
        n = numel(p.getPhase());
        v = p.getVelocity();
        c = p.getColor();
        
        if (ex.localDirection == 0)
            p.setPhase([ex.flankerPhase ex.flankerPhase p.getPhase()]);
            p.setAngle([ex.flankerAngle ex.flankerAngle p.getAngle()]);
            p.setDphase([0 0 0 0 repmat(p.getDphase(), 1, n)]);
            p.setVelocity([v(1) .* [1 1 -1 -1] v]);
        elseif ex.flankerCarriesLocal
            p.setPhase([ex.flankerPhase p.getPhase()]);
            p.setAngle([ex.flankerAngle p.getAngle()]);
            p.setDphase([0 0 repmat(p.getDphase(), 1, n)]);
        else
            p.setPhase([ex.flankerPhase ex.flankerPhase p.getPhase()]);
            p.setAngle([ex.flankerAngle ex.flankerAngle p.getAngle()]);
            p.setColor([c(:,[1 1 1 1]) / sqrt(2) repmat(c, 1, n)]);
            p.setVelocity([v(1) * [1 1 -1 -1] repmat(v, 1, n)]);
            p.setDphase([0 0 0 0 repmat(p.getDphase(), 1, n)]);
            noop();
        end
    end

    this.trials.remove('extra.r');
    this.trials.remove('extra.nTargets');
    this.trials.remove('extra.phase');
    
    this.trials.blockSize = this.trials.numLeft() / 6;
    
%     %for testing
%      this.trials.base.requireFixation = 0;
%      this.trials.startTrial = [];
%      this.trials.endTrial = [];
%      this.trials.blockTrial = [];
%      this.trials.endBlockTrial = [];
%      this.params.inputUsed = {'keyboard', 'knob', 'audioout'};
    
    this.property__(varargin{:});
end
