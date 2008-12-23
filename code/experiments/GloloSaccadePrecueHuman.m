function e = GloloSaccadePrecueHuman(varargin)
    e = GloloSaccadePrecue(varargin{:});
    
    e.trials.startTrial = MessageTrial('message', @()sprintf('Follow the moving target with your eyes when fixation point diasappears.\n%d blocks remain.\nPress space to begin calibration.', e.trials.blocksLeft()));
    e.trials.endBlockTrial = MessageTrial('message', @()sprintf('%d blocks remain.\nPress space to continue.', e.trials.blocksLeft()));
    e.trials.endTrial = MessageTrial('message', sprintf('All done!\nPress space to finish.\nThanks!'));
    
    e.trials.base.extra.distractorRelativeContrast = 1;
end