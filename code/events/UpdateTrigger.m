function this = UpdateTrigger(varargin)
%A trigger that calls its function on every update.
%
%See also Trigger.

log = [];
fn = [];

varargin = assignments(varargin, 'fn');

persistent init__;
this = autoobject(varargin{:});

if isempty(fn)
    set_ = 0;
else
    set_ = 1;
end

    %methods
    function s = check(s)
        if set_
            log('TRIGGER %s %s', func2str(fn), struct2str(s));
            fn(s); %call function always
        end
    end

    function set(f)
        fn = f;
        set_ = 1;
    end

    function unset()
        set_ = 0;
    end

    function setFn(f)
        fn = f;
        set_ = 1;
    end

    function setLog(l)
        log = l;
    end

    function draw(window, toPixels)
    end

    function [release, params] = init(params)
        release = @noop;
    end
end