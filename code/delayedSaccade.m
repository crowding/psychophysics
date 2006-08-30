function delayedSaccade(varargin)

%the options are passed to the setupEyelink initializer, and a sub-option
%'trialOptions' is passed to each trial constructor (for now);
    e = Experiment('trials', MotionRandomizer(), varargin{:});
    e.run();
    
    function this = MotionRandomizer(varargin)
        %the trial generator randomizes above/below fixation, origin
        %and sign of dx, and sign of velocity.
        defaults = struct(...
            'trialConstructor', @SaccadeToTarget...
            );
        
        this = Object(...
            propertiesfromdefaults(defaults, 'params', varargin{:}),...
            public(@hasNext, @next, @result));

        function has = hasNext()
            %randomly generated -- I always have a next one
            has = 1;
        end

        function trial = next(params)
            trial = this.trialConstructor(this.params, params);

            %basic randomization of directions and local motion agreement
            p = trial.params;

            if (rand > 0.5)
                %flip up/down
                c = p.target.center;
                c(2) = -c(2);
                p.params.target.center = c;
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

            trial.params = p;
        end
        
        function result(last)
            %don't care about reshuffling failed trials
        end
    end

end