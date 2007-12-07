function LabJackTimerDemo()

%All timers/counters are enabled and set up as follows: (Note that 0/1 and
%4/5 have been switched! This is because Timer5 is buggy and I need reward
%before I need Plexon...
%
%     FIO4 ---------------------------------- low until plexon scheduled clock
%     
%     FIO5 ----------\                        Timer1, Timer3, VSYNC (rising)
%                    |
%     FIO2 ---------------\           ___     Timer2 -- low until beginning of pulse
%                    |     \-------*--\  \
%     FIO3 ----------*             |  |  |--------- reward pulse
%                    |     /----------/__/
%     FIO0 ---------------/  ___   |          Timer4 -- low until end of pulse
%                    |      /  /---/
%     FIO1 ----------|------|  |              Timer5 -- 1Khz in when FIO2
%                    |      \__\---\
%     FIO6 ----<(----*-----------------VSYNC  Counter0 -- VSYNC(falling)
%                                  |
%     FIO7 ------1Khz--------------/          Counter1 -- 1KHz (rising) when sampling
%
%%
lj = LabJackUE9();
lj.close();
lj.open();
lj.streamStop();
lj.setDebug(1);

lj.portOut('FIO', [1 0 1 0 1 0 1 0], [0 0 0 0 0 0 0 0]);

Priority(9);
Screen('CloseAll');
w = Screen('OpenWindow', 1, 0);

disp('configuring stream')
streamconf = lj.streamConfig...
    ( 'Channels', {'AIN2', 'AIN3', 'Counter0', 'TC_Capture', 'Timer3', 'TC_Capture', 'Timer5', 'TC_Capture'} ...
    , 'Gains', {'Bipolar', 'Bipolar', 'x1', 'x1', 'x1', 'x1', 'x1', 'x1'} ...
    , 'Resolution', 12 ...
    , 'SampleFrequency', 1000 ...
    , 'PulseEnabled', 1 ...
    );
queue = {};
samples = 0;

disp('configuring timers');
beginTimers();


startInfo = Screen('GetWindowInfo', w);
disp('starting stream');
lj.streamStart(GetSecs());
t = GetSecs();

Screen('Flip', w); %this marks refresh 0...

beginTimers();
Screen('FillRect', w,127);
refresh0HWCount = startInfo.VBLCount;

Screen('Flip', w); %this will be refresh 1...
while (GetSecs()) < t + 2;
     x = lj.streamRead();
     if ~isempty(x.data)
         queue = {x queue}; %#ok;
         samples = samples + size(x.data, 2);
     end
end

disp('setting rewards at refresh 300, pulse length of 100');
setReward(400, 100);

while (GetSecs()) < t + 10;
     x = lj.streamRead();
     if ~isempty(x.data)
         queue = {x queue}; %#ok;
         samples = samples + size(x.data, 2);
     end
end

disp('stopping stream')
lj.streamStop();

disp('stopping timers')
stopTimers();



%collapse the linked list
data = zeros(size(queue{1}.data,1), samples);
while ~isempty(queue)
    d = queue{1}.data;
    data(:,samples-size(d, 2)+1:samples) = d;
    samples = samples - size(d,2);
    d = [];
    queue = queue{2};
end

figure(1); clf;

subplot(2, 1, 1);
hold on;
plot(data(3,:), 'r-'); %Counter0, frame count
plot(data(4,:), 'c-'); %Counter0 high, frame count
plot(data(5,:),'g-');  %Timer1 low, stop target
plot(data(6,:),'b-');  %Timer1 high, edges seen
plot(data(7,:),'m-');  %Timer1 high, edges seen
plot(data(8,:),'k-');  %Timer1 high, edges seen
legend('Counter0Lo', 'Counter0Hi', 'Timer3Lo', 'Timer3Hi', 'Timer5Lo', 'Timer5Hi');
hold off;

subplot(2, 1, 2);

hold on;
plot(data(1,:), 'r-');
plot(data(2,:), 'b-');
legend('FIO0', 'FIO2');
hold off;

lj.close();
Screen('CloseAll');

actualclock = data(3,find(data(1,501:end) > 3.3, 1, 'first')+500);
actualreward = data(3,find(data(2,501:end) > 3.3, 1, 'first')+500);
fprintf('Actual clock at %d\n', actualclock);
fprintf('Actual reward at %d\n', actualreward);

    function resp = beginTimers()
        %resp = lj.lowlevel([72 248 12 24 36 7 1 142 1 127 0 255 255 9 0 0 0 255 255 9 0 0 0 255 255 9 0 0 0 0], 40);
        %48F80C18 2407018E 017F00FF FF090000 00FFFF09 000000FF FF090000 0000

        %which means:
        %
        timerconf = lj.timerCounter...
            ( 'Timer0.Mode', 'PWM8',               'Timer0.Value',  0 ...
            , 'Timer1.Mode', 'TimerStop',           'Timer1.Value', 0 ...
            , 'Timer2.Mode', 'PWM8',               'Timer2.Value',  0 ...
            , 'Timer3.Mode', 'TimerStop',           'Timer3.Value', 0 ...
            , 'Timer4.Mode', 'PWM8',               'Timer4.Value',  0 ...
            , 'Timer5.Mode', 'TimerStop',           'Timer5.Value', 0 ...
            , 'Counter0Enabled', 1 ...
            , 'Counter1Enabled', 0 ...
            , 'UpdateReset.Counter0', 1 ...
            )
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
        current = info.VBLCount - refresh0HWCount;
        rewardCounts = max(0, rewardAt - current);
        
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
            ( 'Timer0.Value', 0 ...
            , 'Timer1.Value', rewardCounts ...
            , 'Timer2.Value', 0 ...
            , 'Timer3.Value', rewardCounts + 30 ...
            , 'Timer4.Value', 0 ...
            , 'Timer5.Value', rewardLength ...
            )        
        predictedreward = timerconf.Counter0 + rewardCounts;
        %}
    end
end