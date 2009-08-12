
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
        kd = KeyDown();
        kd.set(@stop, 'q');
        kd.set(@bong, 'space');
        main = mainLoop ...
            ( 'graphics', {disk1, disk2} ...
            , 'triggers', {kd, u} ...
            , 'input', {params.input.keyboard, params.input.trackpad, params.input.mouse, params.input.audioout} ...
            );
%            , 'input', {params.input.keyboard, params.input.trackpad, params.input.audioin, params.input.audioout} ...
        
        params.input.audioout.setFilter(@generateAudio);
        ampl = 0;
        freq = 440;
        lastphase_ = 0;
            
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
            elseif isfield(k, 'mousex')
                disk1.setLoc([k.mousex_deg k.mousey_deg]);
                disk2.setLoc([k.mousex_deg k.mousey_deg]);
                ampl = exp(-10 - k.mousey_deg);
                freq = 440*exp(k.mousex_deg / 5);
%                ampl = k.mouseButtons(1) * 0.9 + 0.05;
            end
        end

        function data = generateAudio(from,data,rate,onset,channels)
            howmany = size(data, 2);
            out = ampl * sin(lastphase_ + (0:howmany-1) * 2*pi*freq/rate);
            data = data + out(ones(numel(channels), 1), :);
            lastphase_ = mod(lastphase_ + howmany * 2*pi*freq/rate, 2*pi); 
        end
        
        function bong(k)
            params.input.audioout.play('ding');
        end
    end

end