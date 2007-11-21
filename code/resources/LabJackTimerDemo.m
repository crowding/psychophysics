%All timers/counters are enabled and set up as follows:
%
%     FIO0 ---------------------------------- low until plexon scheduled clock
%     
%     FIO1 ----------\                        Timer1, Timer3, VSYNC (rising)
%                    |
%     FIO2 ---------------\           ___     Timer2 -- low until beginning of pulse
%                    |     \-------*--\  \
%     FIO3 ----------*             |  |  |--------- reward pulse
%                    |     /----------/__/
%     FIO4 ---------------/  ___   |          Timer4 -- low until end of pulse
%                    |      /  /---/
%     FIO5 ----------|------|  |              Timer5 -- 1Khz in when FIO2
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

disp('configuring stream')
streamconf = lj.streamConfig...
    ( 'Channels', {'AIN2', 'AIN3', 'Counter0', 'Timer1', 'TC_Capture', 'Timer5', 'TC_Capture'} ...
    , 'Gains', {'Bipolar', 'Bipolar', 'x1', 'x1', 'x1', 'x1', 'x1'} ...
    , 'Resolution', 12 ...
    , 'SampleFrequency', 1000 ...
    , 'PulseEnabled', 1 ...
    )


disp('configuring timers');
timerconf = lj.timerCounter...
    ( 'Timer0.Mode', 'PWM16',               'Timer0.Value', 65535 ...
    , 'Timer1.Mode', 'TimerStop',           'Timer1.Value', 0 ...
    , 'Timer2.Mode', 'PWM16',               'Timer2.Value', 65535 ...
    , 'Timer3.Mode', 'TimerStop',           'Timer3.Value', 0 ...
    , 'Timer4.Mode', 'PWM16',               'Timer4.Value', 65535 ...
    , 'Timer5.Mode', 'TimerStop',           'Timer5.Value', 0 ...
    , 'Counter0Enabled', 1 ...
    , 'Counter1Enabled', 0 ...
    , 'UpdateReset.Counter0', 1 ...
    )

disp('starting stream');
t = GetSecs();
lj.streamStart();

queue = {};

samples = 0;

while (GetSecs()) < t + 1;
     x = lj.streamRead();
     if ~isempty(x.data)
         queue = {x queue};
         samples = samples + size(x.data, 2);
     end
end

%see whether we can read the current frame count and schedule a clock-up
%for frame 500

%disp('reading timers');
%timerread = lj.timerCounter()

t1 = 150;% - x.Counter0;
t3 = 250;% - x.Counter0;
t5 = 350;

disp('setting timers')

timerconf = lj.timerCounter...
    ( 'Timer0.Mode', 'PWM16',               'Timer0.Value', 65535 ...
    , 'Timer1.Mode', 'TimerStop',           'Timer1.Value', t1 ...
    , 'Timer2.Mode', 'PWM16',               'Timer2.Value', 65535 ...
    , 'Timer3.Mode', 'TimerStop',           'Timer3.Value', t3 ...
    , 'Timer4.Mode', 'PWM16',               'Timer4.Value', 65535 ...
    , 'Timer5.Mode', 'TimerStop',           'Timer5.Value', t5 ...
    , 'Counter0Enabled', 1 ...
    , 'Counter1Enabled', 0 ...
    )
%stopcheck = lj.timerCounter();

%predict the clock
fprintf('Predicting clock signal at %d\n',  timerconf.Counter0 + t1);
fprintf('Predicting reward signal at %d\n', timerconf.Counter0 + t3);

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
r3 = lj.timerCounter('NumTimers', 0, 'Counter0Enabled', 0, 'Counter1Enabled', 0);

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
plot(data(4,:),'g-');  %Timer1 low, stop target
plot(data(5,:),'b-');  %Timer1 high, edges seen
plot(data(6,:),'m-');  %Timer1 high, edges seen
plot(data(7,:),'k-');  %Timer1 high, edges seen
legend('Counter0', 'Timer1Lo', 'Timer1Hi', 'Timer5Lo', 'Timer5Hi');
hold off;

subplot(2, 1, 2);

hold on;
plot(data(1,:), 'r-');
plot(data(2,:), 'b-');
legend('FIO2', 'FIO4');
lj.close();
hold off;

actualclock = data(3,find(data(1,:) > 3.3, 1, 'first'));
actualreward = data(3,find(data(2,:) > 3.3, 1, 'first'));
fprintf('Actual clock at %d\n', actualclock);
fprintf('Actual reward at %d\n', actualreward);
