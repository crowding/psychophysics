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
        , {'extra.nTargets',                                      'extra.nVisibleTargets', 'motion.process.n',    'extra.min_extent',        'extra.max_extent',        'extra.min_distance'} ...
        , num2cell(num2cell([round(2*pi./configurations.spacing), configurations.nTargets, configurations.nsteps, configurations.min_extent, configurations.max_extent, configurations.min_distance]'), 1));
    this.trials.addBefore('extra.nTargets', 'extra.side', {'left', 'right', 'right', 'left', 'left', 'right', 'right', 'left'}, 1); %side is blocked
    
    %the occluder consists of two cauchy patches
    this.trials.base.occluders = {...
        CauchyDrawer('source', CircularSmoothCauchyMotion( ...
              'omega', 0 ...
            , 'radius', [20/3 20/3] ...
            , 'angle', [0 0]...
            , 'color', [0 0;0 0;0 0] + 0.5/sqrt(2) ...
            , 'phase', [0 0] ...
            , 'localPhase', [0 0] ...
            , 'width', [.05 .05] * 20/3 * 3 ...
            , 'wavelength', [0.075 0.075] * 20/3 ...
            , 'order', [4 4] ...
            , 'localOmega', [0 0] ...
            ));
        };
    
        this.trials.base.occluders = {...
        CauchyDrawer('source', CircularSmoothCauchyMotion( ...
              'omega', 0 ...
            , 'radius', [20/3 20/3 20/3 20/3] ...
            , 'angle', [0 0 0 0]...
            , 'color', [0 0 0 0;0 0 0 0;0 0 0 0] + 0.25/sqrt(2) ...
            , 'phase', [0 0 0 0] ...
            , 'localPhase', [0 0 0 0] ...
            , 'width', [.075 .075 .075 .075] * 20/3 ...
            , 'wavelength', [0.075 0.075 .075 .075] * 20/3 ...
            , 'order', [4 4 4 4] ...
            , 'localOmega', [10 10 -10 -10]*2*pi ...
            ));
        };
    this.trials.base.useOccluders = 1;
    
    this.trials.addBefore('extra.localDirection', {'occluders{1}.source.phase', 'occluders{1}.source.angle', 'extra.phase'}, @occluder);
    function out = occluder(b)
        extra = b.extra;
        %pick a random extent between the min and max extent
        extent = extra.min_extent; %rand() * (extra.max_extent - extra.min_extent) + extra.min_extent;
        movingExtent = 2*pi/extra.nTargets * (extra.nVisibleTargets-1);
        traversed = extra.globalVScalar * b.motion.process.dt * b.motion.process.n
        switch(extra.side)
            case 'left'
                flankPhase = pi + [-0.5 0.5 -0.5 0.5]*extent;
            case 'right'
                flankPhase = [-0.5 0.5 -0.5 0.5]*extent;
        end
        
        switch(extra.globalDirection)
            case -1
                phase = flankPhase(2) - extra.min_distance - movingExtent - rand() * (extent - movingExtent - traversed - 2*extra.min_distance);
            case 1
                phase = flankPhase(1) + extra.min_distance + rand() * (extent - movingExtent - traversed - 2*extra.min_distance);
        end
        
        %phase + movingExtent + .075 * 4
        %extra.min_extent - movingExtent - .075*5
        %extra.max_extent - movingExtent*(extra.nVisibleTargets+1)/(extra.nVisibleTargets-1) - .075*3
        
        out = {flankPhase, flankPhase * 180/pi + 90, phase};
    end

    this.trials.remove('extra.r');
    this.trials.remove('extra.nTargets');
    this.trials.remove('extra.phase');
    
%    this.trials.add('extra.foo', @diag);
%    function out = diag(b)
%        b.occluders{1}.source.phase
%        b.motion.process.phase
%        b.motion.process.phase + b.motion.process.dphase * (b.motion.process.n-1)
%        out = 1;
%    end

    this.trials.blockSize = this.trials.numLeft() / 4;
    
    this.trials.base.requireFixation = 0;

    this.trials.startTrial = [];
    this.trials.endTrial = [];
    this.trials.blockTrial = [];
    this.trials.endBlockTrial = [];
    
    this.property__(varargin{:});
end
