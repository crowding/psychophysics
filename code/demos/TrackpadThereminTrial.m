
function this = TrackpadThereminTrial(varargin)
    persistent init__;
    this = autoobject(varargin{:});
    
    function [params, result] = run(params)
        result = struct();
        
        colorOffset = params.blackIndex;
        colorGain = params.whiteIndex - params.blackIndex;
        border = 0.1;
        
        disk1 = FilledDisk('loc', [0 0], 'color', params.whiteIndex, 'radius', 1, 'visible', 1);
        disk2 = FilledDisk('loc', [0 0], 'color', params.whiteIndex, 'radius', 1, 'visible', 1);
        u = UpdateTrigger();
        u.set(@update);
        main = mainLoop ...
            ( 'graphics', {disk1, disk2} ...
            , 'triggers', {KeyDown(@stop, 'q'), u} ...
            , 'input', {params.input.keyboard, params.input.trackpad, params.input.audioin} ...
            );
            
        main.go(params);
        
        function stop(params)
            main.stop();
        end
        
        function [release, params] = init(params) %for triggering
            release = @noop;
        end

        function k = update(k)
            if isfield(k, 'trackpadLoc')
                if all(~isnan(k.trackpadLoc))
                    disk1.setLoc(k.trackpadLoc);
                    disk2.setLoc(k.trackpadLoc);
                end

                c = disk2.getColor();
                if all(~isnan(k.trackpadAmp))
                    ta = mean(k.trackpadAmp);
                    c(2) = colorOffset + [ta/16] * colorGain;
                    disk2.setRadius(mean(k.trackpadAmp)*10);
                    disk1.setRadius(mean(k.trackpadAmp)*10 + border);
                end
                if ~isempty(k.audio)
                    aa = log(mean(k.audio.^2, 2))/log(10)/3 + 1;
                    c([1 3]) = colorOffset + aa([1 2]) * colorGain;
                end
                disk2.setColor(c);
            end            
        end
    end

    freq = 0;
    ampl = 0;
    lastPhase = 0;
    function data = generateAudio(t)
        phase = mod(lastPhase + (t - lastT)*freq, 2*pi);
        data = sin(phase*2*pi), 
        lastT = t(end);
        lastPhase = t(end);
    end
end