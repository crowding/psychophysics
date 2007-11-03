function this = EyelinkInput(varargin)
    %handles eye position input and recording.

    badSampleCount = 0;
    missingSampleCount = 0;
    goodSampleCount = 0;
    
    this = autoobject(varargin{:});
    
    slowdown_ = [];
    dummy_ = [];
    window_ = [];
    toDegrees_ = [];
    
    %the initializer will be called once per experiment and does global
    %setup of everything.
    function [release, params] = init(params)
        %TODO this should do all the setup!
        release = @noop;
    end


    function [release, details] = begin(details)
        badSampleCount = 0;
        missingSampleCount = 0;
        goodSampleCount = 0;

        if isfield(details, 'slowdown')
            slowdown_ = details.slowdown;
        end
        
        toDegrees_ = transformToDegrees(details.cal);
        
        dummy_ = details.dummy;
        window_ = details.window;

        [clockoffset, details.measured] = getclockoffset(details);
        
        if dummy_
            %do nothing
            release = @noop;
        else
            Eyelink('StartRecording');
            waitSecs(0.1); %pause to allow eyelink to start sending up data?
            
            %{
            % StartRecording is supposed to return a status value, but it
            % doesn't seem to.
            status = Eyelink('StartRecording');
            if status ~= 0
                error('RecordEyes:error', 'status %d starting recording', status);
            end
            %}
            release = @doRelease;
        end

        function doRelease
            Eyelink('StopRecording');

            %{
            %again, the eyelink is supposed to give us a status value, but
            %doesn't.

            status = Eyelink('StopRecording');
            if status ~= 0
            error('RecordEyes:error', 'status %d stopping recording', status);
            end
            %}
        end
    end

    function k = input(k)
        %Takes a sample from the eye, or mouse if the eyelink is not
        %connected. Returns x and y == NaN if the sample has invalid
        %coordinates.

        if dummy_
            [x, y, buttons] = GetMouse(window_);
            
            t = GetSecs() / slowdown_;
            if any(buttons) %simulate blinking
                x = NaN;
                y = NaN;
                badSampleCount = badSampleCount + 1;
            else
                goodSampleCount = goodSampleCount + 1;
            end
        else
            %obtain a new sample from the eye.
            if Eyelink('NewFloatSampleAvailable') == 0;
                x = NaN;
                y = NaN;
                t = GetSecs() / params.slowdown;
                missingSampleCount = missingSampleCount + 1;
            else
                % Probably don't need to do this eyeAvailable check every
                % frame. Profile this call?
                eye = Eyelink('EyeAvailable');
                switch eye
                    case params.el.BINOCULAR
                        error('eyeEvents:binocular',...
                            'don''t know which eye to use for events');
                    case params.el.LEFT_EYE
                        eyeidx = 1;
                    case params.el.RIGHT_EYE
                        eyeidx = 2;
                end

                sample = Eyelink('NewestFloatSample');
                x = sample.gx(eyeidx);
                y = sample.gy(eyeidx);
                if x == -32768 %no position -- blinking?
                    badSampleCount = badSampleCount + 1;
                    x = NaN;
                    y = NaN;
                else
                    goodSampleCount = goodSampleCount + 1;
                end

                t = (sample.time - params.clockoffset) / 1000 / slowdown_;
            end
        end
        [x, y] = toDegrees_(x, y);
        
        k.x = x;
        k.y = y;
        k.t = t;
    end
end