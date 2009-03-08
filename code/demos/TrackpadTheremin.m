function this = TrackpadTheremin(varargin)

    persistent init__;
    this = autoobject(varargin{:});

    e = Experiment();
    e.trials.base = TrackpadThereminTrial();
    e.trials.numBlocks = 1;
    e.trials.blockSize = 1;
    e.trials.endTrial = [];
    
    e.params.input = interface...
        ( struct('keyboard',[],'audioin',[]), e.params.input );
    
    e.params.input.trackpad = TrackpadInput();
    e.params.input.audioin.property__('record', 0, 'channels', [0 1],'freq', 11025);
    e.params.backgroundColor = 0;
    e.filename = '';
    e.subject = 'zzz';
    e.params.logfile = '';
    e.params.log = @noop;
    
    e.run();
end