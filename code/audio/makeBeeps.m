function [tones, samplingrate] = makeBeeps(format, samplingrate)

    if ~exist('samplingrate', 'var') || isempty(samplingrate)
        samplingrate = Snd('DefaultRate');
    end

    %Successive values of format denote frequency, duraiton, and amplitude.
    format = reshape(format, 3, []);
    format = mat2cell(format, [1 1 1]); %each row into a cell

    tones = arrayfun(@tone, format{:}, 'UniformOutput', 0);
    function r = tone(freq, duration, amplitude)
        r = MakeBeep(freq, duration, samplingrate) .* amplitude;
    end
    if isempty(tones)
        tones = {0};
    end
    tones = cat(2, tones{:});

end