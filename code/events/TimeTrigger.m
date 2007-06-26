function this = TimeTrigger(varargin)
% Constructs a trigger that calls a function after a certain time has passed.
% Constructor arguments are the same as for <a href="matlab:help TimeTrigger/set">set</a>.

set_ = 0;
time_ = 0;
fn_ = 0;
valid_ = 0;
log_ = 0;
set(varargin{:})

%----- public interface -----
this = final(@check, @set, @unset, @draw, @setLog, @getFn);

%----- methods -----
    function check(s)
        % Checks the sample and if the time is at or after the trigger's set
        % time, calls the trigger function. If a valid sample is required,
        % checks that x any y are not NaN before calling the trigger
        % function.
        %
        % If the requested time has been exceeded, calls the trigger
        % function, but gives the trigger function the requested time, not
        % the actual time.
        if set_ && (s.t >= time_)  %was 0.13    4396
            %if it must be a valid sample, check then forward
            if ~valid_ || all(~isnan([s.x s.y]))
                s.triggerTime = time_; %note the trigger time in addition to the sample time
                log_('TRIGGER %s %s', func2str(fn_),  'foo'); % struct2str(s));
                fn_(s); %pretend it was triggered on the exact time
            end
        end
    end

    function set(time, fn, valid)
        % function set([time, fn, [valid]])
        %
        % time:  the time after which to call 'fn'.
        % fn:    the function to call. If not given, unsets the trigger.
        % valid: if true, a valid eye position sample must be present to pass the
        %        call.
        if nargin < 2
            set_ = 0;
        else
            time_ = time;
            fn_ = fn;
            valid_ = (nargin >= 3) && valid; %'exist' takes too long
            
            set_ = 1;
        end
    end

    function unset()
        % Inactivates the trigger.
        set_ = 0;
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
        
    function fn = getFn()
        fn = fn_;
    end
end