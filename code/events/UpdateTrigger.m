function this = UpdateTrigger(varargin)
%A trigger that calls its function on every update.
%
%See also Trigger.

logf = [];
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
    notlogged_ = {};
    
    function s = check(s)
        if set_
            fprintf(logf,'TRIGGER %s %s\n', func2str(fn), struct2str(srmfield(s,notlogged_)));
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

    function setLogf(l)
        logf = l;
    end

    function draw(window, toPixels)
    end

    function [release, params] = init(params)
        notlogged_ = params.notlogged;
        release = @noop;
    end
end