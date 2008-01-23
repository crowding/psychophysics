
function this = TrackpadThereminTrial(varargin)
    persistent init__;
    this = autoobject(varargin{:});
    
    function [params, result] = run(params)
        result = 0;
        
        colorOffset = params.blackIndex;
        colorGain = params.whiteIndex - params.blackIndex;
        
        
        disk = FilledDisk('loc', [0 0], 'color', params.whiteIndex, 'radius', 1, 'visible', 1);
        u = UpdateTrigger();
        u.set(@update);
        main = mainLoop ...
            ( 'graphics', disk ...
            , 'triggers', {KeyDown(@stop, 'q'), u} ...
            , 'input', {params.input.keyboard, params.input.trackpad} ...
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
                    disk.setLoc(k.trackpadLoc);
                end

                if all(~isnan(k.trackpadAmp))
                    disk.setColor(colorOffset + mean(k.trackpadAmp) / 32 * colorGain);
                end

                if all(~isnan(k.trackpadSize))
                    disk.setRadius(mean(k.trackpadSize));
                end
            end            
        end
    end
end