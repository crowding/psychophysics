function this = LabJackEyes(varargin)
    %On my rig, the eyes are samples by a LabJack UE9 system which also
    %controls timed pulses to the reward system and data clocking into
    %Plexon.
    %
    %The setup is as follows. The analog channels are streamed at 1000 Hz.
    %
    %Counters are connected as follows:
    %Timer0 (FIO0) - pulled high and outputs to Plexon.
    %Timer1 (FIO1) - receives vertical sync pulse input from computer.
    %Timer2 (FIO2) - pulled high and output to reward system.
    %Timer3 (FIO3) - receives 1000Hz samplign clock from counter1 (FIO1).
    %Timer4 (FIO4) - receives 1000Hz sampling clock 
    %Timer5 (FIO5) - receives vertical sync pulse input.
    %Counter0 (FIO6) - receives vertical sync pulse input.
    %
    %On trial start, timers 1, 3, and 5 are configured to a 'TimerStop'
    %mode with a stop count of 0.
    %
    %SamplingFreq = 1000;
    %
    %Methods are:
    %
    %sendEventCode(code, refresh) -- clocks in the event at the appropriate
    %refresh.
    %
    %reward(refresh, duration) at the appropriate refresh, gives a pulse of
    %the approriate duration (sample duration in msec
    
    this = autoobject(varargin);
    
    FIO0 ---------------------------------- low until plexon scheduled clock
    
    FIO1 ----------\                        
                   |
    FIO2 ---------------\           ___     low until beginning of pulse
                   |     \-------*--\  \
    FIO3 ----------*             |  |  |--  reward pulse
                   |     /----------/__/
    FIO4 ---------------/  ___   |          low until end of pulse
                   |      /  /---/
    FIO5 ----------|------|  |              1Khz in when FIO2 high
                   |      \__\---\
    FIO6 ----------*---------------- VSYNC  Counter0 -- refreshes in trial
                                 |
    FIO7 ------1Khz--------------/          Counter1 -- 1KHz when sampling