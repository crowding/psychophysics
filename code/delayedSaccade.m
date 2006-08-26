function delayedSaccade(varargin)

%the options are passed to the setupEyelink initializer, and a sub-option
%'trialOptions' is passed to each trial constructor (for now);

details = namedargs('trialOptions', struct(), varargin{:});



require(setupEyelinkExperiment(details), @runExperiment);
    function runExperiment(details)

        %slow down when in mouse mode
        if details.dummy && ~isfield(details.trialOptions, 'timeDilation')
            details.trialOptions.timeDilation = 3;
        end

        for i = 1:40

            %some trivial randomization
            trial = generateTrial(details.trialOptions);
            %EyelinkDoDriftCorrection(details.el);
            trial.run(details);
        end
    end



    function trial = generateTrial(trialOptions)
        trial = SaccadeToTarget(trialOptions);

        %trivial randomization
        p = trial.params();

        if (rand > 0.5)
            %flip up/down
            c = p.target.center;
            c(2) = -c(2);
            p.target.center = c;
        end

        if (rand > 0.5)
            %flip horizontally
            c = p.target.center;
            c(1) = -c(1);
            p.target.center = c;
            dx = p.target.dx;
            p.target.dx = -dx;

            v = p.target.primitive.velocity;
            p.patch.primitive.velocity = -v;

        end

        if (rand > 0.5)
            %correct versus antidromic local motion
            v = p.target.primitive.velocity;
            p.target.primitive.velocity = -v;
        end

        trial.setParams(p);

    end


end