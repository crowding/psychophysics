function this = KnobThreshold(varargin)

%fire a trigger when the knob position reaches one of two values.
%Note that the knob is not 1-1 with the world.

cwFn = @noop;
cwThreshold = Inf;
ccwFn = @noop;
ccwThreshold = -Inf;

set_ = 0;
log = @noop;

varargin = assignments(varargin, 'cwFn', 'cwThreshold', 'ccwFn', 'ccwThreshold');

persistent init__;
this = autoobject(varargin{:});

    function check(s)
        if (set_)
            if s.knobPosition <= ccwThreshold
                log('TRIGGER %s %s', func2str(ccwFn), struct2str(s));
                ccwFn(s);
            end
            if s.knobPosition >= cwThreshold
                log('TRIGGER %s %s', func2str(cwFn), struct2str(s));
                cwFn(s);
            end
        end
    end

    function set(cwF, cwThresh, ccwF, ccwThresh)
        cwFn = cwF;
        cwThreshold = cwThresh;
        ccwFn = ccwF;
        ccwThreshold = ccwThresh;
        set_ = 1;
    end

    function unset()
        set_ = 0;
    end

    function [release, params] = init(params)
        release = @noop;
    end
end