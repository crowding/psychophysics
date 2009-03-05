function this = TrackpadTheremin(varargin)

    persistent init__;
    this = autoobject(varargin{:});

    e = Experiment();
    e.trials.base = TrackpadThereminTrial();
    e.trials.numBlocks = 1;
    e.trials.blockSize = 1;
    
    e.params.input.trackpad = TrackpadInput();
    e.params.input.audio = AudioIO();
    e.params.backgroundColor = 0;
    e.filename = '';
    e.subject = 'zzz';
    e.params.logfile = '';
    e.params.log = @noop;
    
    e.run();
end