function t = triggers(eventname, trial, varargin)
    %return the triggers from a trial matching a perticular string.
    t = trial.triggers(find(cellfun('prodofsize',regexp({trial.triggers.name},eventname, 'match')), varargin{:}));
end