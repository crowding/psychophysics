function results = myExperimentCatch(arg)
    [window, rect] = Screen('openWindow', 0);
    
    try
        results = doMyExperiment(arg);

        Screen('Close', window);
    catch
        Screen('Close', window);
    end
end

function result = doMyExperiment(arg)
    if arg == 1
        result = 'good data!';
    elseif arg == 2
        error('a:b', 'the flergleflam is not connected to the thingamabob');
    end
end