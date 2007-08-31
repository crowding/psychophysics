function testPMD1208FS
    duration = 5;
    
    device = PMD1208FS...
        ('options', struct...
            ( 'f',  1000 ...
            , 'channel', [0 1] ...
            , 'range', [2 2] ...
            , 'immediate', 0 ...
            , 'trigger', 0 ...
            , 'secs', 0 ...
            ) ...
        );
    
    device.reset();
    require(device.init, @doTest);
    
    function doTest
        start = GetSecs();
        device.AInScanBegin();

        ns = 0;
        i = 0;
        while (GetSecs() < start + duration)
            samples = device.AInScanSample();
            ns = ns + numel(samples);
            i = i + 1;
        end
        stop = GetSecs();
        device.AInStop();
        i
        ns
        ns / (stop - start)
    end
end

