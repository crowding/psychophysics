function this = RefreshTrigger(varargin)
% Constructs a trigger that calls a function after a a certain number of
% refreshes have elapsed (i.e. like TimeTrigger, but locked to the screen
% refresh.)

isSet = 0;
refresh = 0;
fn = @noop;
log = @noop;

%----- public interface -----
this = autoobject(varargin{:});

%----- methods -----
    function check(x, y, t, next, r)
        % Checks the sample and if the time is at or after the trigger's set
        % time, calls the trigger function. If a valid sample is required,
        % checks that x any y are not NaN before calling the trigger
        % function.
        %
        % If the requested time has been exceeded, calls the trigger
        % function, but gives the trigger function the requested time, not
        % the actual time.
        if set && (r >= refresh)
            %if it must be a valid sample, check then forward
            if ~valid_ || all(~isnan([x y]))
                log('TRIGGER %f, %f, %f, %f, %f, %s', x, y, t, next, r, func2str(fn_));
                fn(x, y, t, next, r);
            end
        end
    end

    function set(refresh_, fn_, valid_)
        % function set([refresh, fn, [valid]])
        %
        % refresh:  the time after which to call 'fn'.
        % fn:    the function to call. If not given, unsets the trigger.
        % valid: if true, a valid eye position sample must be present to pass the
        %        call.
        if nargin < 2
            isSet = 0;
        else
            time = time_;
            fn = fn_;
            valid = exist('valid_', 'var') && valid_;
            
            isSet = 1;
        end
    end

    function unset()
        % Inactivates the trigger.
        set = 0;
    end

    function draw(window, toPixels)
        % Draw the number of seconds remaining in the upper right corner of
        % the screen.
        %
        % window: the window number.
        % toPixels: a transform from degrees to pixels
        if set_
            t = time_ - GetSecs();
            Screen('DrawText', window, sprintf('%0.3f', t), 20, 20, [0 255 0] );
        end
    end

    function setLog(log)
        log_ = log;
    end
        
end