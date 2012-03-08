function defaults_pastorianus()
defaults('set', 'Screen', 'requireCalibration', 1);
defaults('set', 'Screen', 'priority', 1);

defaults('set', 'EyelinkInput', 'edfname', '' ); %no record, stream!
defaults('set', 'EyelinkInput', 'doTheTrackerSetup', 1);

defaults('set', 'Screen', 'screenNumber', 1 );
defaults('set', 'Screen', 'resolution', {800 600 120 32});
defaults('set', 'Screen'  , 'imagingMode', kPsychNeed16BPCFloat);

defaults('set', 'Experiment', 'inputUsed', {'eyes', 'knob', 'keyboard', 'audioout'});

%the serial port???
%'port', 1 ...

end