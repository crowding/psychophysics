function e = delayedSaccade(varargin)

params = namedargs(varargin{:});

%the options are passed to the setupEyelink initializer, and a sub-option
%'trialOptions' is passed to each trial constructor (for now);
    e = Experiment(...
        'trials', MotionRandomizer(params)...
        ,'description', 'cued saccade to apparent motion stimulus.'...
        ,'instructions', sprintf([...
'Fixate at the dot. A moving stimulus will appear. When the dot \n'...
'disappears, make a saccade to the moving stimulus. During a trial, press'... 
'''q'' to abort the experiment.'...
]);
        ,params);
    
    e.run();
    
    function this = MotionRandomizer(varargin)
        %the trial generator randomizes above/below fixation, origin
        %and sign of dx, and sign of velocity.

        %Default parameter values:
        %'cueWindow' gives the location of the window, in degrees, inside
        %which the saccade cue may be given. Negative is to the side the
        %target comes from.
        %
        %'cueRatePerDegree' gives the hazard rate for being cued when the
        %stimulus is inside the window.
        defaults = struct(...
            'cueWindow', [-3 1]...
            ,'cueRatePerDegree', 0.4 ...
            ,'err', [] ...
            );
        
        this = Object(...
            propertiesfromdefaults(defaults, 'params', varargin{:}),...
            public(@hasNext, @next, @result));

        %----- method definitions -----
        
        
        function has = hasNext()
            %in this paradigm I always have a next trial
            %we may want to put rest periods, trial blocks, etc. in here
            has = 1;
        end

        
        function trial = next(params)
            %----- construct and return the next trial -----
            trial = SaccadeToTarget(this.params, params);
            
            %basic randomization of directions and local motion agreement
            p = trial.trialParams;

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
                
                window = -this.cueWindow;
            else
                window = this.cueWindow;
            end

            if (rand > 0.5)
                %correct versus antidromic local motion
                v = p.target.primitive.velocity;
                p.target.primitive.velocity = -v;
            end
            
            %choose when to give the cue
            t = cueTime(...
                p.target.center(1), p.target.dx / p.target.dt,...
                window, this.cueRatePerDegree);
            p.cueTime = t;
            if isnan(t)
                p.cueSaccade = 0;
            end

            trial.trialParams = p;
        end
        
        
        function result(last)
            %trials are drawn from a distribution -- I
            %don't care about reshuffling failed trials
            if ~isempty(last.err)
                rethrow(last.err);
            end
        end
        
        
        function time = cueTime(origin, speed, window, rate)
            %exponentially distributed times that catch a moving object
            %inside a window. If the object should not be caught,
            %NaN is returned.
            
            startTime = (window(1) - origin) / speed;
            endTime = (window(2) - origin) / speed;
            
            ratePerTime = rate*abs(speed);
            timeFromStart = exprnd(1/ratePerTime);
            
            time = timeFromStart + startTime;
            if time > endTime
                time = NaN;
            end
            
        end
    end

end