function this = measure(this, varargin);
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
    , 'screenNumber', this.screenNumber...
    , 'oversample', 5 ...
    , 'retry', 3 ...
    , 'timeout', 2 ...
    );
params = namedargs(defaults, varargin{:});

require(...
    getScreen(params), ...
    openComm(), ...
    @takeMeasurements);

    function params = takeMeasurements(params)

        %set identity gamma table for the measurement
        oldgamma = Screen(params.screenNumber, 'LoadNormalizedGammaTable', ...
            linspace(0,1,256)'*[1 1 1]);

        %get the photometer location
        message(params, 'click where the photometer is attached on-screen');
        [clicks, x, y] = GetClicks(params.window);
        this.calibration_rect = [x y x y] + [-75 -75 75 75];

        %fill background with 0 and foreground with 255, then do reading
        Screen('FillRect', params.window, 0);
        Screen('FillRect', params.window, 255, this.calibration_rect);
        Screen('Flip', params.window);

        %let's take readings on a grid of 20 voltage values for each of
        %background and foreground, linearly spaced.
        [background, foreground] = meshgrid(linspace(0,1,20), linspace(0,1,20));
        oversample = 5
        readings = zeros(numel(background), oversample + 2);

        for bf = [background(:)';foreground(:)';1:numel(background)]
            bf
            Screen(params.screenNumber, 'LoadNormalizedGammaTable', ...
                linspace(bf(1),bf(2),256)'*[1 1 1]);
            WaitSecs(3);
            readings(bf(3), :) = [bf(1), bf(2), take_reading(params)' ];
        end

        this.measurement = readings;
        this.measured = 1;
    end




    function reading = take_reading(params)
        tries = 0;
        reading = [];
        while (length(reading) < params.oversample) & (tries < params.retry)
            %talk to the photometer and try to obtain 3 readings.
            comm('write', params.port, sprintf('!NEW %d\r', params.oversample));
            time = GetSecs;
            response = '';
            while (length(reading) < params.oversample) && (GetSecs < time + params.timeout)
                response = comm('readl', params.port);

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
    end



    function init = openComm(varargin)
        init = currynamedargs(@doOpenComm, varargin{:});
        
        function [releaser, params] = doOpenComm(params)
            comm('open', params.port, params.portconfig);
            comm('write', params.port, sprintf('!NEW\r'));
            WaitSecs(1);
            string = comm('readl', params.port);
            if (length(string) == 0)
                release();
                error('no photometer detected');
            end
            releaser = @release;
            
            function release
                comm('close', params.port);
            end
        end
    end

end