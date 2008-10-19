function this = LabJackInput(varargin)

%A logic circuit attached to the lapjack helps produce the following signals:
%
%     FIO0 outputs high until plexon scheduled clock
%     FIO1 receives rising edges of monitor VSYNC
%     FIO2 outputs high until beginning of reward pulse, then low
%     FIO3 receives rising edges of monitor VSYNC
%     FIO4 outputs high until end of reqard pulse, then low
%     FIO5 recieves inverted sample clock from FIO6, only when FIO2 is low
%     FIO6 recieves inverted VSYNC signal (falling edges) for Counter0
%     FIO7 outputs falling edges at 1Khz sampling rate.
%
% IMPORTANT NOTE FOR INTEL MACS: If you are not geting good latency out of
% this hardware you need to turn off the delayed ACK feature in OS X.
%
% To to this, issue the command:
% sudo systcl -w net.inet.tcp.delayed_ack=0
%
% To do it semipermanently, add "net.inet.tcp.delayed_ack=0" to the file
% /etc/sysctl.conf (you can create this file if it doesn't exist.)

%%
persistent slope;
persistent offset;
persistent calibrationDate;
persistent calibrationSubject;

lj = LabJackUE9();

if isempty(slope)
    slope = 10 * eye(2); % a 2*2 matrix relating voltage to eye position
    offset = [0;0]; % the eye position offset
end

persistent init__; %#ok
this = autoobject(varargin{:});

%keep track of how much fluid was given this session
persistent fluidToday;
fluidInSession = 0;
fluidSchedule = [0 0;1000 0.6]; %/ms reward....
%measured 10/18/08 on charlie's chair/modified lixit:

%500 * 75 = 24 ml
%500 * 100 = 30 ml
%500 * 150 = 42 ml
%2250 * 200 = 270 ml

%seems like 0.0006 m/ms flow rate

if isempty(fluidToday)
    fluidToday = 0;
end

data = zeros(3,0);

w_ = 0;
log_ = @noop;

%% init function
    function [release, params, next] = init(params)
        defaults = struct...
            ( 'streamConfig', struct...
                ( 'Channels', {{'AIN0', 'AIN1', 'Counter0'}}...
                , 'Gains', {{'Bipolar', 'Bipolar', 'x1'}} ...
                , 'Resolution', 14 ...
                , 'SampleFrequency', 1000 ...
                , 'PulseEnabled', 1 ...
                )...
            );
        
        x = joinResource(defaults, @ljReset, lj.init, @logFluid, @myInit);
        [release, params, next] = x(params);

        function [release, params] = ljReset(params)
            lj.reset(1);
%            require(lj.init, @()lj.reset(1));
            %waitSecs(5);
            release = @noop;
        end
        
        function [release, params] = myInit(params)
            lj.streamStop();
            lj.portOut('FIO', [1 0 1 0 1 0 1 0], [1 0 0 0 0 0 0 0]);
            
            %weirdness --- setting the timers to something other than 0
            %seems to be necessary to get out of a bad mode...
            lj.timerCounter...
                ( 'Timer0.Mode', 'PWM8',               'Timer0.Value',  0 ...
                , 'Timer1.Mode', 'TimerStop',           'Timer1.Value', 1 ...
                , 'Timer2.Mode', 'PWM8',               'Timer2.Value',  0 ...
                , 'Timer3.Mode', 'TimerStop',           'Timer3.Value', 1 ...
                , 'Timer4.Mode', 'PWM8',               'Timer4.Value',  0 ...
                , 'Timer5.Mode', 'TimerStop',           'Timer5.Value', 1 ...
                , 'Counter0Enabled', 1 ...
                , 'Counter1Enabled', 0 ...
                , 'UpdateReset.Counter0', 1 ...
                );
            
            resp = lj.streamConfig(params.streamConfig);
            assert(strcmp(resp.errorcode, 'NOERROR'), 'error configuring stream');

            params.obtainedSampleFrequency = resp.SampleFrequency;
            params.eyeSampleRate = params.streamConfig.SampleFrequency;
            
            if isfield(params, 'log')
                log_ = params.log;
            else
                log_ = @noop;
            end
            

            assert(strcmp(resp.errorcode, 'NOERROR'));
        
            
            release = @close;
            function close()
                lj.streamStop();
                stopTimers();
                lj.portOut('FIO', [1 0 0 0 0 0 0 0], [1 0 0 0 0 0 0 0]);
            end
        end
        
        function [release, params] = logFluid(params)
            release = @l;
            
            fluidInSession = 0;
            
            function l()
                fprintf('%5f ml fluid this run  (%5f ml today)\n', fluidInSession, fluidToday);
                log_('FLUID run=%f;today=%f', fluidInSession, fluidToday);
            end
        end
    end


%% begin trial function
    streamStartTime_ = 0;
    push_ = @noop;
    readout_ = @noop;
    function [release, params] = begin(params)
        lj.flush();

        resp = lj.streamConfig(params.streamConfig);
        assert(strcmp(resp.errorcode, 'NOERROR'), 'error configuring stream');

        params.notlogged = union(params.notlogged, {'eyeX', 'eyeY', 'eyeT', 'eyeRefreshes', 'rawEyeX', 'rawEyeY'});

        % {
        %4BF80C18 2D01018E 017F0100 00090000 01000009 00000100 00090000 0000
        resp = lj.lowlevel([75 248 12 24 45 1 1 142 1 127 1 0 0 9 0 0 1 0 0 9 0 0 1 0 0 9 0 0 0 0], 40);
        assert( resp(7) == 0, 'labjack returned error setting timers' );
        % }

        %WEIRDO ISSUE: if the labjack doesn't timer properly, set the
        %timers to 1 once...
        
        %which means:
        %
        %{
        %lj.setDebug(1);
        resp = lj.timerCounter...
            ( 'Timer0.Mode', 'PWM8',               'Timer0.Value',  0 ...
            , 'Timer1.Mode', 'TimerStop',           'Timer1.Value', 1 ...
            , 'Timer2.Mode', 'PWM8',               'Timer2.Value',  0 ...
            , 'Timer3.Mode', 'TimerStop',           'Timer3.Value', 1 ...
            , 'Timer4.Mode', 'PWM8',               'Timer4.Value',  0 ...
            , 'Timer5.Mode', 'TimerStop',           'Timer5.Value', 1 ...
            , 'Counter0Enabled', 1 ...
            , 'Counter1Enabled', 0 ...
            , 'UpdateReset.Counter0', 1 ...
            );
        assert(strcmp(resp.errorcode, 'NOERROR'));
        %lj.setDebug(0);
        %}
        
        streamStartTime_ = GetSecs();
        resp = lj.streamStart(); %sync() is necessary as well, but should be called later in the main loop...
        if ~strcmp(resp.errorcode, 'NOERROR')
            @noop;
        end
        
        w_ = params.window;
        
        [push_, readout_] = linkedlist(2); %concatenate horizontally
        
        streamRead_ = lj.streamRead; %access just the function, not the whole struct, for speed

        release = @close;
        
        params.eyeSampleRate = params.obtainedSampleFrequency;
        
        function close
            stopTimers();
            lj.streamStop();
            %final data capture
            input(struct());
            lj.flush();

            %TODO log it here...
            data = readout_();
            data([3 4],:) = data([4 3], :);
            log_('EYE_DATA %s', smallmat2str(data));
        end
    end


%% sync (called just before refresh 1?
    refresh0HWCount_ = 0;
    function sync(refresh, time)  %#ok
        syncInfo = Screen('GetWindowInfo', w_);
        refresh0HWCount_ = syncInfo.VBLCount - refresh;
        
        % {
        %4BF80C18 2D01018E 017F0100 00090000 01000009 00000100 00090000 0000
        resp = lj.lowlevel([75 248 12 24 45 1 1 142 1 127 1 0 0 9 0 0 1 0 0 9 0 0 1 0 0 9 0 0 0 0], 40);
        assert( resp(7) == 0, 'labjack returned error setting timers' );
        %}
        
        %weirdness here. When you set the timers to zero, *usually* it all
        %works, but then it stops. Setting timers to one fixes?
        
        %which means:
        %
        %{
        %lj.setDebug(1);
        resp = lj.timerCounter...
            ( 'Timer0.Mode', 'PWM8',               'Timer0.Value',  0 ...
            , 'Timer1.Mode', 'TimerStop',           'Timer1.Value', 1 ...
            , 'Timer2.Mode', 'PWM8',               'Timer2.Value',  0 ...
            , 'Timer3.Mode', 'TimerStop',           'Timer3.Value', 1 ...
            , 'Timer4.Mode', 'PWM8',               'Timer4.Value',  0 ...
            , 'Timer5.Mode', 'TimerStop',           'Timer5.Value', 1 ...
            , 'Counter0Enabled', 1 ...
            , 'Counter1Enabled', 0 ...
            , 'UpdateReset.Counter0', 1 ...
            );
        assert(strcmp(resp.errorcode, 'NOERROR'));
        %lj.setDebug(0);
        %}
    end



    refresh0HWCount_ = 0;

    lastX_ = NaN;
    lastY_ = NaN;
    lastT_ = NaN;
    streamRead_ = lj.streamRead;
    
    function h = input(h)
        x = streamRead_();
        raw = x.data([1 2], :);
        h.rawEyeX = raw(1,:);
        h.rawEyeY = raw(2,:);
        h.eyeT = x.t + streamStartTime_;
        h.eyeRefreshes = x.data(3,:);
        
        calibrated = slope*raw+offset(:,ones(1,size(raw, 2)));
        h.eyeX = calibrated(1,:);
        h.eyeY = calibrated(2,:);
        
        if ~isempty(x.data)
            %build up a trace
            push_([x.data;x.t + streamStartTime_]);
            lastX_ = calibrated(1,end);
            lastY_ = calibrated(2,end);
            lastT_ = h.eyeT(end);
        end
        h.x = lastX_;
        h.y = lastY_;
        h.t = lastT_;
        
        if GetSecs() - lastT_ > 0.5;
            disp('WHAT HAPPENED:(');
        end
    end

    function [data, t, latest] = extractData()
        %collapse the linked list
        data = readout_();
        t = data(end,:);
        data(end,:) = [];
        latest = t(end);
    end

    function demo()
        
        sc = struct...
            ( 'Channels', {{'AIN2', 'AIN3', 'Counter0', 'Timer1', 'TC_Capture'}} ...
            , 'Gains', {{'Bipolar', 'Bipolar', 'x1', 'x1', 'x1'}} ...
            , 'Resolution', 10 ...
            );
        
        [params, data, t] = require...
            ( HighPriority('streamConfig', sc)...
            , getScreen('screenNumber', 1, 'requireCalibration', 0, 'skipSyncTests', 1)...
            , @init, @begin, @collectData);

        actualclock = data(3,find(data(1,501:end) > 3.3, 1, 'first')+500);
        actualreward = data(3,find(data(2,501:end) > 3.3, 1, 'first')+500);
        fprintf('Actual clock at %d\n', actualclock);
        fprintf('Actual reward at %d\n', actualreward);

        figure(1); clf;

        hold on;
        subplot(2, 1, 1);
        plot(t, data(3,:), 'k-', t, data(4, :), 'c-', t, data(5, :), 'r-');
        legend('Counter0', 'Timer1Lo', 'Timer1Hi');
        subplot(2, 1, 2);
        plot(t, data(1,:), 'r-', t, data(2, :), 'b-');
        legend('AIN2', 'AIN3')
        
        
%       [ax, h1, h2] = plotyy(t, data(3,:), t, data(1,:));
%       hold(ax(1), 'on');
%       h3 = plot(ax(1), t, data(4,:), 'g-');  %Timer1 low, stop target
%       h4 = plot(ax(1), t, data(6,:), 'g-');  %Timer3 low, stop target
%       hold(ax(2), 'on');
%       h5 = plot(ax(2), t, data(2,:), 'b-');
%       legend([h1 h2], 'Sync', 'Reward');%, 'Frame Count', 'Timer1Lo', 'Timer3Lo', 'Location', 'NorthEastOutside');

        hold off;

        function [params, data, t] = collectData(params)
            w_ = params.window;
            
            t = GetSecs();
            setupSync();
            collectUntil(t + 0.2);
            predictedreward = reward(60, 200)
            predictedclock = eventCode(70, 42)
            collectUntil(t + 1.0);
            [data, t] = extractData();
        end

        function setupSync()
            Screen('Flip', w_); %this marks refresh 0...
            sync(0);
            Screen('FillRect', w_,127);
            Screen('DrawingFinished', w_);
            Screen('Flip', w_); %this will be refresh 1...
        end

        function collectUntil(t)
            x.t = 0;
            while max(x.t, GetSecs()) < t;
                x = input(struct());
            end
        end
    end

    function resp = stopTimers()
        %9FF80C18 82000180 01000000 00000000 00000000 00000000 00000000 0000
        resp = lj.lowlevel([159 248 12 24 130 0 1 128 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0], 40);

        %which encodes:
        %{
       r3 = lj.timerCounter('NumTimers', 0, 'Counter0Enabled', 0, 'Counter1Enabled', 0);
        %}
    end

    function [predictedreward, time] = reward(rewardAt, rewardLength)
        %ask the screen for a current refresh count...
        info = Screen('GetWindowInfo', w_);
        current = info.VBLCount - refresh0HWCount_;
        rewardCounts = max(1, rewardAt - current);

        %calculate the fluid amount
        fluid = interp1(fluidSchedule(:,1), fluidSchedule(:,2), rewardLength, 'cubic', 'extrap');
        
        %
        % {
        %1DF80C18 FF000100 013C0000 00000000 00000000 5D000000 00006400 0000
        packet = [29 248 12 24 255 0 1 0 1 60 0 0 0 0 0 0 0 0 0 0 93 0 0 0 0 0 100 0 0 0];
        packet(21) = bitand(rewardCounts, 255);
        packet(22) = bitshift(rewardCounts, -8);
        packet(27) = bitand(rewardLength, 255);
        packet(28) = bitshift(rewardLength, -8);
        response = lj.lowlevel(packet, 40);
        assert(response(7) == 0, 'error setting timer');
        predictedreward = double(response(33:36))*[1;256;65536;16777216] + rewardCounts;
        % }

        %equivalent to:
        %{
        lj.setDebug(1);
        timerconf = lj.timerCounter...
            ( 'Timer2.Value', 0 ...
            , 'Timer3.Value', rewardCounts ...
            , 'Timer4.Value', 0 ...
            , 'Timer5.Value', rewardLength ...
            );
        lj.setDebug(0);
        predictedreward = timerconf.Counter0 + rewardCounts;
        %}

        fluidInSession = fluidInSession + fluid;
        fluidToday = fluidToday + fluid;
        time = info.LastVBLTime + info.VideoRefreshFromBeamposition * (predictedreward - info.VBLCount + refresh0HWCount_);
        log_('REWARD %d %d %d %f %f', rewardAt, rewardLength, predictedreward, info.LastVBLTime + info.VideoRefreshFromBeamposition * (predictedreward - info.VBLCount + refresh0HWCount_), fluid);
    end

    %send out an 8-bit event code.
    function predictedclock = eventCode(clockAt, code)
        %D1A30301 FF2A0000
        
        % {
        packet1 = [209 163 3 1 255 42 0 0];
        packet1(6) = code;
        resp = lj.lowlevel(packet1, 8);
        assert(resp(7) == 0, 'error outputting code');
        
        info = Screen('GetWindowInfo', w_);
        current = info.VBLCount - refresh0HWCount_;
        clockCounts = max(1, clockAt - current);

        %9AF80C18 7D000100 01030000 00007800 00000000 00000000 00000000 0000
        packet2 = [154 248 12 24 125 0 1 0 1 3 0 0 0 0 120 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0];
        packet2(15) = bitand(clockCounts, 255);
        packet2(16) = bitshift(clockCounts, -8);
        resp = lj.lowlevel(packet2, 40);
        assert(resp(7) == 0, 'error setting timer');
        predictedclock = double(resp(33:36))*[1;256;65536;16777216] + clockCounts;
        % }
        
        %equivalent to:
        %{
        %lj.setDebug(1);
        lj.portOut('EIO', 255, code);
        
        info = Screen('GetWindowInfo', w_);
        current = info.VBLCount - refresh0HWCount_;
        clockCounts = max(1, clockAt - current);

        timerconf = lj.timerCounter...
            ( 'Timer0.Value', 0 ...
            , 'Timer1.Value', clockCounts ...
            )
        predictedclock = timerconf.Counter0 + clockCounts;
        x = lj.timerCounter()
        [bitshift(x.Timer1, -16) bitand(x.Timer1, 65535)]

        %lj.setDebug(0);
        %}
        
        log_('EVENT_CODE %d %d %d', clockAt, code, predictedclock);
    end

end
