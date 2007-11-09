function this = KnobPress(varargin)
%fire a trigger on press of a knob.

fn = @noop;
set_ = 0;
log = @noop;
varargin = assignments(varargin, 'fn');
this = autoobject(varargin{:});

    function set(f)
        fn = f;
        set_ = 1;
    end

    function unset()
        set = 0;
    end

    function check(s)
        if set_ && s.knobDown > 0
            log('TRIGGER %s %s', str2func(fn), struct2str(s));
            fn(s);
        end
    end
        
    function [release, params] = init(params)
        release = @noop;
    end
end