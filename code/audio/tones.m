function player = tones(format, samplingrate)
%function player = tones(format, samplingrate)
%makes an audio player with a sequence of tones. format is a matrix where
%each column has (freq, duration, amplitude) with duration in seconds.
%Sampling rate defaults to 8192 Hz.

if ~exist('samplingrate', 'var')
    samplingrate = [];
end
[t, samplingrate] = makeBeeps(format);

player = audioplayer(t, samplingrate);