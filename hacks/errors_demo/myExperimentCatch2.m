function results = myExperimentCatch2(arg)
    [window, rect] = Screen('openWindow', 0);
    try
        results = doMyExperiment(arg);

        Screen('Close', window);
    catch err
        Screen('Close', window);
        rethrow(err);
    end
end

function result = doMyExperiment(arg)
    if arg == 1
        result = 'good data!';
    elseif arg == 2
        error('a:b', 'the flergleflam is not connected to the thingamabob');
    elseif arg == 3
        Screen('DrawDots', 'dsfargeg');
    end
end