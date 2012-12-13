function defaults_bayanus()

defaults('set', 'Experiment',   'subject',     'zzz');
defaults('set', 'Experiment',   'filename', '');
defaults('set', 'Experiment',   'inputUsed',     {'keyboard', 'audioout'});

defaults('set', 'EyelinkInput', 'edfname',     '');
defaults('set', 'EyelinkInput', 'localname',    '');
defaults('set', 'EyelinkInput', 'dummy',       1);

defaults('set', 'ConcentricAdjustmentTrial', 'useEyes', 0);
defaults('set', 'ConcentricAdjustmentTrial', 'useKnob', 1);

defaults('set', 'ConcentricTrial', 'requireFixation', 0);

defaults('set', 'Screen',       'imagingMode', kPsychNeed16BPCFloat);
defaults('set', 'Screen', 'preferences', 'skipSyncTests', 1);
defaults('set', 'Screen', 'requireCalibration', 0);
defaults('set', 'Screen', 'hideCursor', 0 );

if length(screen('Screens')) < 2
    defaults('set', 'Screen', 'rect', [100 100 512 512] )
    defaults('set', 'Screen', 'cal' ...
            , Calibration( 'interval', 1/60, 'distance', 180/pi ...
                         , 'spacing', [40/512, 40/512], 'rect', [100 100 512 512] ...
                         ) ...
            );
end

defaults('set', 'highPriority',     'priority', 0);

end