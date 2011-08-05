function this = ConcentricDirectionSegment(varargin)
    this = ConcentricDirectionConstant();
    this.caller=getversion(1);
    
    %now, rather than a cross up of all target numbers and all target
    %densities, we want to select them from a grid of values that work
    
    this.trials.reps = 1;
    
    %we have another script for generating some configurations...
    configurations = occlusiongen();
    this.trials.base.extra.r = 20/3;
    this.trials.addBefore...
        ( 'extra.nTargets' ...
        , {'extra.nTargets',                                      'extra.nVisibleTargets', 'extra.globalVScalar',   'motion.process.n',    'extra.min_extent',        'extra.max_extent',        'extra.min_distance'} ...
        , num2cell(num2cell([round(2*pi./configurations.spacing), configurations.nTargets, configurations.stepsize, configurations.nsteps, configurations.min_extent, configurations.max_extent, configurations.min_distance]'), 1));
    this.trials.addBefore('extra.nTargets', 'extra.side', {'left', 'right', 'right', 'left', 'left', 'right', 'right', 'left'}, 1); %side is blocked
    
    %the occluder consists of two cauchy patches
    this.trials.base.occluders = {...
        CircularSmoothCauchyMotion( ...
              'omega', 0 ...
            , 'radius', [20/3 20/3] ...
            , 'angle', [0 0]...
            , 'color', [0 0] + 0.5/sqrt(2) ...
            , 'phase', [0 0] ...
            , 'localPhase', [0 0] ...
            , 'width', .075 * 20/3 * 3 ...
            , 'wavelength', 0.075 * 20/3 ...
            , 'order', [4 4] ...
            , 'localOmega', [0 0] ...
            );
        };
    
    this.trials.addBefore('extra.nTargets', {'occluders{1}.phase', 'occluders{1}.angle', 'extra.phase'}, @occluder);
    function out = occluder(b)
        extra = b.extra;
        %pick a random extent between the min and max extent
        extent = rand() * (extra.max_extent - extra.min_extent) + extra.min_extent;
        switch(extra.side)
            case 'left'
                flankPhase = pi + [-0.5 0.5]*extent;
            case 'right'
                flankPhase = [-0.5 0.5]*extent;
        end
        
        switch(extra.globalDirection)
            case -1
                phase = flankPhase(2) - rand() * (extent - extra.min_extent) - extra.min_distance;
            case 1
                phase = flankPhase(1) + rand() * (extent - extra.min_extent) + extra.min_distance;
        end

        out = {flankPhase, flankPhase * 180/pi + 90, phase};
    end

    this.trials.remove('extra.r');
    this.trials.remove('extra.nTargets');

    this.trials.blockSize = this.trials.numLeft() / 4;
        
%for testing
    this.trials.blockTrial = [];
    this.trials.startTrial = [];
    this.trials.requireSuccess = [];
    this.trials.endBlockTrial = [];
    this.trials.endTrial = [];

        
    this.property__(varargin{:});
end
