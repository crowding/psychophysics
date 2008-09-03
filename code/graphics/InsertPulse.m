function this = InsertPulse(varargin)

process = [];
pulseAt = [];
pulse = struct();

persistent init__; %#ok
this = autoobject(varargin{:});

counter_ = 0;

    function reset()
        counter_ = 0;
        process.reset();
    end

    function s = next()
        s = process.next();
        counter_ = counter_ + 1;
        if any(counter_ == pulseAt)
            for i = fieldnames(pulse)'
                s.(i{1}) = pulse.(i{1});
            end
        end
    end
end