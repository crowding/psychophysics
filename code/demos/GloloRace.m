function this = GloloRace(varargin)

    persistent init__;
    this = autoobject(varargin{:});

    e = Experiment();
    e.trials.base = GloLoRaceTrial();
    e.trials.numBlocks = 1;
    e.trials.blockSize = 1;
    
    e.filename = '';
    e.subject = 'zzz';
    e.params.logfile = '';
    e.params.log = @noop;
    
    e.run();
end