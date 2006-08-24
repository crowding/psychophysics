function player = tones(format, samplingrate)
%function player = tones(format, samplingrate)
%makes an audio player with a sequence of tones. format is a matrix where
%each column has (freq, duration, amplitude) with duration in seconds.
%Sampling rate defaults to 8192 Hz.

if ~exist('samplingrate', 'var')
    samplingrate = 8192;
end

params = reshape(format, 3, []);
params = num2cell(params, [2]); %each row into a cell
tones = arrayfun(@tone, params{:}, 'UniformOutput', 0);
player = audioplayer(cat(2, tones{:}), samplingrate);

    function r = tone(freq, duration, amplitude)
        r = MakeBeep(freq, duration, samplingrate) .* amplitude;
    end

end