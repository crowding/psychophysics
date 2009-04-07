function times = triggerTimes(eventname, trial, varargin)
%function times = triggerTimes(eventname, trial, varargin)
%returns the trigger times for any triggers patching that name.
    t = triggers(eventname, trial, varargin{:});
    times = [t.next];
end