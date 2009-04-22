function results = myExperimentCatch3(arg)
    [window, rect] = Screen('openWindow', 1);
    
    try
        results = doMyExperiment(arg);
    catch err
        try
            Screen('Close', window);
        catch err2
            %not addCause! See HELP ADDERROR.
            err = adderror(err2, err); %remember what went wrong originally...
        end
        rethrow(err);
    end
    Screen('Close', window);    
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