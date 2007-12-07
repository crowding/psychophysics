function this = LabJackEyes(varargin)
%On my rig, the eyes are samples by a LabJack UE9 system which also
%controls timed pulses to the reward system and data clocking into
%Plexon.
%
%The setup is as follows. The analog channels are streamed at 1000 Hz.
%
%All timers/counters are enabled and set up as follows:
%
%     FIO0 ---------------------------------- low until plexon scheduled clock
%     
%     FIO1 ----------\                        
%                    |
%     FIO2 ---------------\           ___     low until beginning of pulse
%                    |     \-------*--\  \
%     FIO3 ----------*             |  |  |--  reward pulse
%                    |     /----------/__/
%     FIO4 ---------------/  ___   |          low until end of pulse
%                    |      /  /---/
%     FIO5 ----------|------|  |              1Khz in when FIO2 high
%                    |      \__\---\
%     FIO6 ----<(---*-----------------VSYNC   Counter0 (falling edges)
%                                  |
%     FIO7 ------1Khz--------------/          Counter1 -- 1KHz when sampling
%

device = LabJackUE9();
log = @noop; %the data will be logged while the 


function [release, params] = init(params);
    r = joinResource(device.init, @configureTimersAndStream();
    [release, params] = r(params);

    device.timerCounter...
        ( 'Timer0.Mode', 'PWM16',       'Timer0.Value', 0 ...
        , 'Timer1.Mode', 'StopTimer',   'Timer1.Value', 0 ...
        , 'Timer2.Mode', 'PWM16',       'Timer2.Value', 0 ...
        , 'Timer3.Mode', 'StopTimer',   'Timer2.Value', 0 ...
        , 'Timer3.Mode'

    device.streamConfig...
        ( 'Timer1.Mode', 
        );
end

function [release, params] = begin(params);
    %start the stream and set the timers
    device.timerCounter(
        ('Timer1.Value', 0, 'Timer3.Value', 0, 'Timer5.Value', 0 ...
        
    device.streamStart();
    release = device.streamEnd();
end

    function setTimers
