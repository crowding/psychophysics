    function times = triggerTimes(eventname, trial)
        %returns the trigger times for any triggers patching that name.
        t = triggers(eventname, trial);
        times = [t.next];
    end