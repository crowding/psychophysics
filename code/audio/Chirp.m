function this = Noise(varargin)
    %a chopped noise.
    
    length = 0.1; %in seconds.
    attack = 0.000; %impose a ramp at the start
    release = 0.005; %impose a ramp at the end
    decay = 0.01; %in seconds (time constant).
    beginfreq = 440;
    endfreq = 1;
    sweep = 'linear';
    
    persistent init__;
    this = autoobject(varargin{:});
    
    function data = e(channels, rate)
        nSamples = round(length*rate);
        
        %generate chirp
        switch sweep
            case 'linear'
                freq = linspace(beginfreq, endfreq, nSamples) ./ rate .* 2 .* pi;
            case 'quadratic'
                freq = linspace(sqrt(beginfreq), sqrt(endfreq), nSamples).^2 ./ rate .* 2 .* pi;
            case 'exponential'
                freq = logspace(log10(beginfreq), log10(endfreq), nSamples) ./ rate .* 2 .* pi;
            otherwise
                error('chirp:unknownSweep', 'Sweep must be ''linear'', ''quadratic'' or ''exponential'' (got %s)', sweep);
        end

        data = sin(cumsum(freq));
        data = data(ones(numel(channels), 1), :);

        %impose ramps and decays
        data(:,1:floor(attack*rate)) = data(:,1:floor(attack*rate)) .* ( ones(numel(channels), 1) * linspace(0, 1, floor(attack*rate)) );
        data(:,end-floor(release*rate)+1:end) = data(:,end-floor(release*rate)+1:end) .* ( ones(numel(channels), 1) * linspace(1, 0, floor(release*rate)) );
        data = data .* ones(numel(channels), 1) .* exp(-(0:nSamples-1)./rate./decay);
    end 
end