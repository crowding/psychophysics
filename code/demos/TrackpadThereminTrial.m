
function this = TrackpadThereminTrial(varargin)
    persistent init__;
    this = autoobject(varargin{:});
    
    function [params, result] = run(params)
        result = struct();
        
        colorOffset = params.blackIndex;
        colorGain = params.whiteIndex - params.blackIndex;
        border = 0.1;
        
        disk1 = FilledDisk('loc', [0 0], 'color', [0;1;0]*params.whiteIndex, 'radius', 1, 'visible', 1);
        disk2 = FilledDisk('loc', [0 0], 'color', [0;1;0]*params.whiteIndex, 'radius', 1, 'visible', 1);
        u = UpdateTrigger();
        u.set(@update);
        main = mainLoop ...
            ( 'graphics', {disk1, disk2} ...
            , 'triggers', {KeyDown(@stop, 'q'), u} ...
            , 'input', {params.input.keyboard, params.input.trackpad, params.input.audioin, params.input.audioout} ...
            );
        
        params.input.audioout.setOutputFunction(@generateAudio);
        ampl = 0.9;
            
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
                    ampl = ta;
                    c(2) = colorOffset + [ta/16] * colorGain;
                    disk2.setRadius(mean(k.trackpadAmp)*10);
                    disk1.setRadius(mean(k.trackpadAmp)*10 + border);
                end
        %        if ~isempty(k.audio)
        %            %ampl = sqrt(mean(mean(k.audio.^2,2)));
        %            aa = max(0,log(ampl)/log(10)/3 + 0.99);
        %            c([1 3]) = colorOffset + aa * colorGain;
        %        end
                disk2.setColor(c);
            end            
        end

        function out = generateAudio(from,howmany,rate,onset)
            out = ampl * sin((from:from+howmany-1) * 2*pi*660/rate);
        end
    end

end