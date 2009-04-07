function t = triggers(eventname, trial, varargin)
%function t = triggers(eventname, trial, varargin)
%return the triggers from a trial matching a perticular string. 'varargin'
%gives extra arguments to be passed to FIND (e.g. (... 1, 'first') if you just
%want the first trigger)
    t = trial.triggers(find(cellfun('prodofsize',regexp({trial.triggers.name},eventname, 'match')), varargin{:}));
end