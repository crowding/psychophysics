function PMDTriggerTest(varargin)
    %attempts to synchronize the beginning of data acquisition of hte PMD with the
    %screen refresh. Use a scope on the PMD's sync signal and the VGA
    %signal to verify. Seems to work!
    
    defaults = struct ...
        ( 'backgroundColor', 0 ...
        , 'requireCalibration', 0 ...
        , 'preferences', struct...
            ( 'skipSyncTests', 2 ...
            ) ...
        , 'daqOptions', struct ...
            ( 'channel', [0 1 0 1 0 1 0 1] ...
            , 'range', [1 1 1 1 1 1 1 1] ...
            , 'f', 1000 ...
            , 'immediate', 0 ...
            , 'trigger', 1 ...
            , 'triggerSlope', 0 ...
            ) ...
        );
            
    params = namedargs(defaults, varargin{:});
    
    device = PMD1208FS('options', params.daqOptions);
    
    require(getScreen(params), highPriority(), device.init, @go);
    
    function go(params)
        %setup recording
        interval = Screen('GetFlipInterval', params.window);
        
        %start with black screen
        for i = 1:10
            [VBL] = Screen('Flip', params.window);
        end
        
        Screen('FillRect', params.window, 255);
        
        device.AInScanBegin(VBL + interval);
        
        [VBL] = Screen('Flip', params.window);
        ns = 0;
        for i = 0:9
            Screen('FillRect', params.window, 64 + 127.5 * mod(i,2));
            Screen('DrawingFinished', params.window);
            [samples, t] = device.AInScanSample();
            ns = ns + numel(t);
            [VBL] = Screen('Flip', params.window);
        end
        [lostdata, data, t] = device.AInStop();
        
        ns = ns + numel(t);
        
        for i = 1:10        
            Screen('FillRect', params.window, 0);
            [VBL] = Screen('Flip', params.window);
        end
        ns
    end
        
end