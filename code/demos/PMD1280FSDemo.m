function this = PMD1280FSDemo(varargin)

%I want to sample X and Y at 1000 Hz, and receive at least 240
%packets/second. At 31 samples/packet, I need 7440 samples/sec.
%So on two channels, do this by oversampling 4x:

    defaults = struct ...
        ( 'daqOptions', struct ...
            ( 'f', 1000 ...
            , 'channel', [0 1 0 1 0 1 0 1] ... %sample channels 1 and 2 repeatedly for oversampling
            , 'range', [2 2 2 2 2 2 2 2] ...
            , 'immediate', 0 ...
            , 'trigger', 0 ... %set this to 1 and connect the vsync line
            ...                %from the monitor port to the PMD's trigger
            ...                %input, and sample start will be
            ...                %synchronized with the flame 
            ) ...
        , 'preferences', struct('skipSyncTests', 2) ...
        , 'backgroundColor', 0 ...
        , 'foregroundColor', 1 ...
        , 'requireCalibration', 0 ...
        , 'history', 10000 ... %how many points to draw on the screen at once
        , 'bigSparkColor', [20 10 0] ...
        , 'bigSparkSize', 20 ...
        , 'bigSparkVelocity', 20 ... %pixels per second
        , 'littleSparkColor', [0 127 255] ...
        , 'littleSparkSize', 2 ...
        , 'littleSparkVelocity', 50 ... %pixels per second
    );
        
    params = namedargs(defaults, varargin{:});
    device = PMD1208FS('options', params.daqOptions);
    %device.reset();

    require(getScreen(params), device.init, highPriority(), @runDemo);
    function runDemo(params)
        %scale the full sampling of the ADC onto the screen.
        offset = (params.rect([3 4]) + params.rect([1 2]))' / 2;
        vmax = device.vmax();
        gain = (params.rect([3 4])' - offset) ./ vmax([1;2]) / 2;
    
        interval = Screen('getFlipInterval', params.window);
        
        %add like sparkles
        Screen('BlendFunction', params.window, 'GL_SRC_ALPHA', 'GL_ONE');
        
        [VBL] = Screen('Flip', params.window);
        device.AInScanBegin(VBL + interval);
        [samples, t] = device.AInScanSample();
        [VBL] = Screen('Flip', params.window);

        %run until mouse is pressed
        buttons = [];
        sampleHistory = zeros(2,0);
        tHistory = zeros(1,0);
        vHistory = zeros(2,0);
        while ~any(buttons)
            
            %apply oversampling and gain corrections
            samples = [mean(samples(1:2:end, :), 1); mean(samples(2:2:end, :), 1)];
            samples = samples .* gain(:, ones(1, size(samples, 2))) + offset(:, ones(1, size(samples, 2)));
           
            %remember the most recent points for drawing to the screen
            nPoints = params.history;
            nNewPoints = min(size(samples,2),nPoints);
            sampleHistory = ...
                [ sampleHistory(:, max(1, end-(nPoints)+nNewPoints+1):end) ...
                , samples(:, end-nNewPoints+1:end) ...
                ];
            tHistory = ...
                [ tHistory(:, max(1, end-(nPoints)+nNewPoints+1):end) ...
                , t(:, end-nNewPoints+1:end) ...
                ];
            vHistory = ...
                [ vHistory(:, max(1, end-(nPoints)+nNewPoints+1):end) ...
                , randn(2, nNewPoints) ...
                ];
            
            
            if size(sampleHistory, 2) >= 1
                %sparks move
                coords = sampleHistory + ((VBL + interval) - tHistory([1;1], :)).*vHistory*params.bigSparkVelocity;
                Screen('DrawDots', params.window, coords, params.bigSparkSize, params.bigSparkColor, [], 1);
                coords = sampleHistory + ((VBL + interval) - tHistory([1;1], :)).*vHistory*params.littleSparkVelocity;
                Screen('DrawDots', params.window, coords, params.littleSparkSize, params.littleSparkColor, [], 1);
            end

            Screen('DrawingFinished', params.window);
            
            %grab more samples
            [samples, t] = device.AInScanSample();
            [x, y, buttons] = GetMouse();
            
            VBL = Screen('Flip', params.window, VBL + interval/2);
        end
        
        device.AInStop();
        
    end

end
