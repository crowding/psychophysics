function LabJackTimerDemo()

%A circuit attached to the lapjack helps produce the following signals:
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
%%
lj = LabJackUE9();
lj.setDebug(0);
demo();

w = 0;

%% init function
    function [release, params] = init(params)
        x = joinResource(lj.init, @myInit);
        [release, params] = x(params);

        function [release, params] = myInit(params)
            lj.streamStop();
            lj.flush();
            lj.portOut('FIO', [1 0 1 0 1 0 1 0], [1 0 1 0 1 0 1 0]);

            streamconf = lj.streamConfig...
                ( 'Channels', {'AIN2', 'AIN3', 'Counter0', 'Timer1', 'TC_Capture', 'Timer3'} ...
                , 'Gains', {'Bipolar', 'Bipolar', 'x1', 'x1', 'x1', 'x1'} ...
                , 'Resolution', 12 ...
                , 'SampleFrequency', 1000 ...
                , 'PulseEnabled', 1 ...
                );

            assert(strcmp(streamconf.errorcode, 'NOERROR'), 'error configuring stream');

            release = @close;
            function close()
                lj.streamStop();
                stopTimers();
                lj.portOut('FIO', [0 0 0 0 0 0 0 0], [0 0 0 0 0 0 0 0]);
            end
        end
    end


%% begin trial function
    function [release, params] = begin(params)
        queue_ = {};
        samples_ = 0;

        lj.streamStart(); %sync() is necessary as well, but should be called later in the main loop...

        release = @close;

        function close
            lj.streamStop();
            %TODO sample and log to the log here...
            queue_ = {};
            samples_ = 0
            lj.flush();
        end
    end

w = 0;
queue_ = {};
samples_ = 0;
refresh0HWCount_ = 0;

        function data = extractData()
            %collapse the linked list
            data = zeros(size(queue_{1}.data,1), samples_);
            while ~isempty(queue_)
                d = queue_{1}.data;
                data(:,samples_-size(d, 2)+1:samples_) = d;
                samples_ = samples_ - size(d,2);
                d = [];
                queue_ = queue_{2};
            end
            queue_ = {};
            samples_ = 0;
        end

    function demo()
        [params, data] = require(HighPriority(), getScreen('screenNumber', 1, 'requireCalibration', 0), @init, @begin, @collectData);

        actualclock = data(3,find(data(1,501:end) > 3.3, 1, 'first')+500);
        actualreward = data(3,find(data(2,501:end) > 3.3, 1, 'first')+500);
        fprintf('Actual clock at %d\n', actualclock);
        fprintf('Actual reward at %d\n', actualreward);

        figure(1); clf;

        hold on;
        d = 1:size(data, 2);
        [ax, h1, h2] = plotyy(d, data(3,:), d, data(1,:));
        hold(ax(1), 'on');
        h3 = plot(ax(1), data(4,:));  %Timer1 low, stop target
        h4 = plot(ax(1), data(6,:));  %Timer1 high, edges seen
        hold(ax(2), 'on');
        h5 = plot(ax(2), d, data(2,:));
        legend([h1 h2], 'Sync', 'Reward');%, 'Frame Count', 'Timer1Lo', 'Timer3Lo', 'Location', 'NorthEastOutside');

        hold off;

        legend('FIO0', 'FIO2', 'Location', 'NorthEastOutside');
        hold off;
        
        function [params, data] = collectData(params)
            w = params.window;

            t = getSecs();
            setupSync();
            
            collectUntil(t+0.5);
            
            predictedreward = setReward(120, 100);
            predictedclock = setClock(150);

            collectUntil(t+2);

            data = extractData();
        end

        function setupSync()
            Screen('Flip', w); %this marks refresh 0...
            startInfo = Screen('GetWindowInfo', w);
            Screen('FillRect', w,127);
            Screen('DrawingFinished', w);
            params.refresh0HWCount = startInfo.VBLCount;
            params = sync(params);
            Screen('Flip', w); %this will be refresh 1...
        end

        function collectUntil(t)
            while (GetSecs()) < t;
                x = lj.streamRead();
                if ~isempty(x.data)
                    queue_ = {x queue_}; %#ok;
                    samples_ = samples_ + size(x.data, 2);
                end
            end
        end
    end


    refresh0HWCount_ = 0;
    function params = sync(params)
        %resp = lj.lowlevel([72 248 12 24 36 7 1 142 1 127 0 255 255 9 0 0 0 255 255 9 0 0 0 255 255 9 0 0 0 0], 40);
        %48F80C18 2407018E 017F00FF FF090000 00FFFF09 000000FF FF090000 0000

        %which means:
        %
        refresh0HWCount_ = params.refresh0HWCount;
        resp = lj.timerCounter...
            ( 'Timer0.Mode', 'PWM8',               'Timer0.Value',  0 ...
            , 'Timer1.Mode', 'TimerStop',           'Timer1.Value', 0 ...
            , 'Timer2.Mode', 'PWM8',               'Timer2.Value',  0 ...
            , 'Timer3.Mode', 'TimerStop',           'Timer3.Value', 0 ...
            , 'Timer4.Mode', 'PWM8',               'Timer4.Value',  0 ...
            , 'Timer5.Mode', 'TimerStop',           'Timer5.Value', 0 ...
            , 'Counter0Enabled', 1 ...
            , 'Counter1Enabled', 0 ...
            , 'UpdateReset.Counter0', 1 ...
            );
        %}
    end

    function resp = stopTimers()
        %9FF80C18 82000180 01000000 00000000 00000000 00000000 00000000 0000
        resp = lj.lowlevel([159 248 12 24 130 0 1 128 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0], 40);

        %which encodes:
        %{
       r3 = lj.timerCounter('NumTimers', 0, 'Counter0Enabled', 0, 'Counter1Enabled', 0);
        %}
    end

    function predictedreward = setReward(rewardAt, rewardLength)
        %ask the screen for a current refresh count...
        info = Screen('GetWindowInfo', w);
        current = info.VBLCount - refresh0HWCount_;
        rewardCounts = max(1, rewardAt - current);

        %{
        %5EF80C18 3C050100 013C0000 00000000 00FFFF00 9E0000FF FF006400 0000
        packet = [94 248 12 24 60 5 1 0 1 60 0 0 0 0 0 0 0 255 255 0 158 0 0 255 255 0 100 0 0 0]
        packet(18) = bitand(rewardCounts, 255);
        packet(19) = bitshift(rewardCounts, -8);
        packet(24) = bitand(rewardLength, 255);
        packet(25) = bitshift(rewardLength, -8);
        response = lj.lowlevel(packet, 40);

        predictedreward = double(response(33:36))*[1;256;65536;1677216] + rewardCounts;
        fprintf('Predicting reward signal at %d\n', predictedreward);
        %}

        %equivalent to:
        %
        timerconf = lj.timerCounter...
            ( 'Timer2.Value', 0 ...
            , 'Timer3.Value', rewardCounts ...
            , 'Timer4.Value', 0 ...
            , 'Timer5.Value', rewardLength ...
            );
        predictedreward = timerconf.Counter0 + rewardCounts;
        %}
    end

    function predictedclock = setClock(clockAt)
        info = Screen('GetWindowInfo', w);
        current = info.VBLCount - refresh0HWCount_;
        clockCounts = max(1, clockAt - current);

        timerconf = lj.timerCounter...
            ( 'Timer0.Value', 0 ...
            , 'Timer1.Value', clockCounts ...
            );
        predictedclock = timerconf.Counter0 + clockCounts;
    end
end
