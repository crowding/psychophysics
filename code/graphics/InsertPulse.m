function this = InsertPulse(varargin)

process = [];
pulseAt = [];
pulse = struct();

persistent init__; %#ok
this = autoobject(varargin{:});

persistent index__;
index_ = struct('x', 1, 'y', 2, 't', 3, 'angle', 4, 'color', [5 6 7], 'width', 8, 'duration', 9, 'wavelength', 10, 'velocity', 11, 'order', 12, 'phase', 13);

counter_ = 0;

    function reset()
        counter_ = 0;
        process.reset();
    end

    function s = next()
        s = process.next();
        for i = 1:numel(s,2)
            if counter_+i == pulseAt
                for f = fieldnames(pulse)'
                    s(index_.(f{1}),i) = pulse.(f{1});
                end
            end
        end
        counter_ = counter_ + size(s,2);
    end
end