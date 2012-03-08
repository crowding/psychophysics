function defaults_global()
defaults('set', 'Screen', 'preferences', 'SkipSyncTests', 0);
defaults('set', 'Screen', 'backgroundColor', 0.5 );
defaults('set', 'Screen', 'foregroundColor', 0 );
defaults('set', 'Screen', 'preferences', 'SkipSyncTests', 0 );
defaults('set', 'Screen', 'preferences', 'TextAntiAliasing', 0 );
defaults('set', 'Screen', 'requireCalibration', 1 );
defaults('set', 'Screen', 'resolution', [] );
defaults('set', 'Screen', 'imagingMode', kPsychNeed16BPCFloat); % good graphics cards on this rig, get good imaging
defaults('set', 'Screen', 'rect', []);

defaults('set', 'Experiment', 'inputConstructors', 'keyboard', @KeyboardInput);
defaults('set', 'Experiment', 'inputConstructors', 'mouse',    @MouseInput);
defaults('set', 'Experiment', 'inputConstructors', 'eyes',     @EyelinkInput);
defaults('set', 'Experiment', 'inputConstructors', 'knob',     @PowermateInput);
defaults('set', 'Experiment', 'inputConstructors', 'keyboard', @KeyboardInput);
defaults('set', 'Experiment', 'inputConstructors', 'audioin',  @AudioInput);
defaults('set', 'Experiment', 'inputConstructors', 'audioout', @AudioOutput);

defaults('set', 'AudioOutput', 'samples', 'ding',  Ding('freq', 880, 'decay', 0.1, 'damping', 0.04));
defaults('set', 'AudioOutput', 'samples', 'click', Chirp('beginfreq', 1000, 'endfreq', 1e-6, 'length', 0.05, 'decay', 0.01, 'release', 0.005, 'sweep', 'exponential'));
defaults('set', 'AudioOutput', 'samples', 'buzz',  Ding('attack', 0, 'freq', 72, 'length', 0.2, 'decay', Inf, 'damping', 0.1, 'release', 0.05));

sounds = dir('/System/Library/Sounds/*.aiff');
for sound = sounds(:)'
    path = fullfile('/System/Library/Sounds', sound.name);
    [~, name, ~] = fileparts(path);
    defaults('set', 'AudioOutput', 'samples', name, path);
end

defaults('set', 'Experiment', 'inputUsed', {{'keyboard'}});

end