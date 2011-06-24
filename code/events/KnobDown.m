function this = KnobDown(varargin)
    fn = [];
    logf = [];
    
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
        if set_ && s.knobDown > 0
            fprintf(logf,'TRIGGER %s %s\n', func2str(fn), struct2str(s));
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