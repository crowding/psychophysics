function [params] = measure(varargin);
%Tries to communicate with a LumaColor photometer connected by a serial port.
%(defaults to serial port 2)
%Sets the screen to each gray value 0:255 and reads the luminance.
%Returns the grayscales in the first column and the raw luminance values
%in the second.

%The comm library being used will crash matlab at the slightest problem.
%Apparently there is a simple fix for this, which has not been made here.


defaults = struct(...
      'port', 2 ...
    , 'portconfig', '2400,n,8,1'...
    , 'screenNumber', 0 ...
    , 'oversample', 5 ...
    , 'retry', 3 ...
    , 'timeout', 2 ...
    , 'settle', 3 ...
    , 'photometer_size', 200 ...
    , 'calibration_rect', [] ...
    , 'background', [] ...
    , 'foreground', [] ...
    , 'readings', [] ...
    , 'requireCalibration', 0 ...
    );
params = namedargs(defaults, varargin{:});

params = require(...
    getScreen(params), ...
    openComm(), ...
    @takeMeasurements);

    function params = takeMeasurements(params)

        %set identity gamma table for the measurement
        oldgamma = Screen(params.screenNumber, 'ReadNormalizedGammaTable');

        %get the photometer location
        if isempty(params.calibration_rect)
            message(params, 'click where the photometer is attached on-screen');
            [clicks, x, y] = GetClicks(params.window);
            params.calibration_rect = [x y x y] + [-1 -1 1 1]*params.photometer_size./2;
            
            %get the cursor out of there
            SetMouse(0, 0, params.screenNumber);
        end
        
        %fill background with 0 and foreground with 255, then do reading
        Screen('FillRect', params.window, 0);
        Screen('FillRect', params.window, 255, params.calibration_rect);
        Screen('Flip', params.window);

        %let's take readings on a grid of 20 voltage values for each of
        %background and foreground, linearly spaced.
        params.readings = zeros(numel(params.background), params.oversample);

        for bf = [params.background(:)'; params.foreground(:)'; 1:numel(params.background)]
            disp(bf')
            Screen(params.screenNumber, 'LoadNormalizedGammaTable', ...
                linspace(bf(1),bf(2),256)'*[1 1 1]);
            WaitSecs(params.settle);
            params.readings(bf(3), :) = take_reading(params)';
        end
        
        params.readings = mean(params.readings, 2);
        params = rmfield(params, 'cal');
    end


    function reading = take_reading(params)
        tries = 0;
        reading = [];
        while (length(reading) < params.oversample) & (tries < params.retry)
            %talk to the photometer and try to obtain 3 readings.
            SerialComm('write', params.port, sprintf('!\r'));
            WaitSecs(0.1);
            SerialComm('purge', params.port);
            SerialComm('write', params.port, sprintf('!NEW %d\r', params.oversample));
            time = GetSecs;
            response = '';
            while (length(reading) < params.oversample) && (GetSecs < time + params.timeout)
                response = SerialComm('readl', params.port);
                disp(response);
                %use regexp to match...
                response = regexp(response, '\d[^\n\r]*', 'match');

                if (length(response) > 0)
                    time = GetSecs;
                    reading = cat(1, reading, sscanf(response{1}, '%f'));
                end
            end

            if (length(reading) < params.oversample)
                if (tries >= 3)
                    error('error reading from photometer');
                elseif (tries < 3)
                    warning('timeout, retrying...');
                    tries = tries + 1;
                end
            end
        end
        SerialComm('write', params.port, sprintf('!\r'));
        WaitSecs(0.1);
        SerialComm('purge', params.port);
    end



    function init = openComm(varargin)
        init = currynamedargs(@doOpenComm, varargin{:});
        
        function [releaser, params] = doOpenComm(params)
            SerialComm('open', params.port, params.portconfig);
            SerialComm('write', params.port, sprintf('!NEW\r'));
            WaitSecs(1);
            string = SerialComm('readl', params.port);
            if (length(string) == 0)
                release();
                error('no photometer detected');
            end
            releaser = @release;
            
            function release
                SerialComm('close', params.port);
            end
        end
    end

end