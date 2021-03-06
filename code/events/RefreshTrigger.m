
function this = RefreshTrigger(varargin)
% Constructs a trigger that calls a function after a a certain number of
% refreshes have elapsed (i.e. like TimeTrigger, but locked to the screen
% refresh.)

isSet = 0;
refresh = 0;
last = 0;
valid = 0;
fn = @noop;
logf = [];

%----- public interface -----
persistent init__;
this = autoobject(varargin{:});

%----- methods -----
    function s = check(s)
        % Checks the sample and if the time is at or after the trigger's set
        % time, calls the trigger function. If a valid sample is required,
        % checks that x any y are not NaN before calling the trigger
        % function.
        %
        % If the requested time has been exceeded, calls the trigger
        % function, but gives the trigger function the requested time, not
        % the actual time.
        last = s.refresh;
        if isSet && (s.refresh >= refresh)
            %if it must be a valid sample, check then forward
            if ~valid || all(~isnan([s.x s.y]))
                s.triggerRefresh = refresh;
                fprintf(logf,'TRIGGER %s %s\n', func2str(fn), struct2str(s));
                fn(s);
            end
        end
    end

    function [release, params] = init(params)
        release = @noop;
    end

    function set(fn_, refresh_, valid_)
        % function set([refresh, fn, [valid]])
        %
        % refresh:  the time after which to call 'fn'.
        % fn:    the function to call. If not given, unsets the trigger.
        % valid: if true, a valid eye position sample must be present to pass the
        %        call.
        if ~isnumeric(refresh_)
            error('refreshTrigger:badInput', 'input 2 must be numeric');
        elseif nargin < 2
            isSet = 0;
        else
            refresh = refresh_;
            fn = fn_;
            valid = exist('valid_', 'var') && valid_;
            isSet = 1;
        end
    end

    function unset()
        % Inactivates the trigger.
        isSet = 0;
    end

    function draw(window, toPixels)
        % Draw the number of frames remaining in the upper right corner of
        % the screen.
        %
        % window: the window number.
        % toPixels: a transform from degrees to pixels
        if isSet
            t = refresh;
            Screen('DrawText', window, sprintf('%d %s', t - last, func2str(fn)), 20, 20, [0 255 0] );
        end
    end
        
end