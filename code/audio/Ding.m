function this = Ding(varargin)
    %a ding sound, maybe more pleasant than a pure tone.
    
    freq = 768;
    length = 0.5; %in seconds.
    attack = 0.005; %impose a ramp at the start
    release = 0.01; %impose a ramp at the end
    damping = 0.03; %damping per cycle.
    decay = 0.1; %in seconds (time constant).
    
    persistent init__;
    this = autoobject(varargin{:});
    
    function data = e(channels, rate)
        nSamples = round(length*rate);
        cycle = rate/freq;
        data = ones(numel(channels), nSamples);
        data(:, mod((0:end-1) / cycle - 0.25, 1) > 0.5) = -1;
        %each cycle becomes a damped version of the last...

        for index = cycle+3:cycle:nSamples-cycle
            to = floor(index):ceil(index+cycle-1);
            from = (floor(index - cycle)-1:floor(index - cycle)+to(end)-to(1)+1);
            data(:, to) = conv2(data(:,from), [damping 1-2*damping damping], 'valid');
%           plot(data(to(1)-10:to(end)+10));
%           drawnow;
        end
        data(to+1:end) = 0;
        
        data(:,1:floor(attack*rate)) = data(:,1:floor(attack*rate)) .* ( ones(numel(channels), 1) * linspace(0, 1, floor(attack*rate)) );
        data(:,end-floor(release*rate)+1:end) = data(:,end-floor(release*rate)+1:end) .* ( ones(numel(channels), 1) * linspace(1, 0, floor(release*rate)) );
        data = data .* ones(numel(channels), 1) .* exp(-(0:nSamples-1)./rate./decay);
    end 
end