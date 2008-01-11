function this = KnobRotate(varargin)
    %calls the trigger function every time the powermate rotation is
    %nonzero.
    
    fn = [];
    log = @noop;
    
    set_ = [];

    varargin = assignments(varargin, 'fn');
    if ~isempty(fn) && isempty(set_)
        set_ = 1;
    elseif isempty(set_)
        set_ = 0;
    end

    persistent init__;
    this = autoobject(varargin{:});
    
    function set(fn_)
        fn = fn_;
        set_ = 1;
    end
    
    function s = check(s)
        if set_ && s.knobRotation ~= 0
            log('TRIGGER %s %s', func2str(fn), struct2str(s));
            fn(s);
        end
    end

    function unset()
        set_ = 0;
    end

    function [release, params] = init(params)
        release = @noop;
    end
end