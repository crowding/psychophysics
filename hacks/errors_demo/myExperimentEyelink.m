function results = myExperimentEyelink(arg)
    [window, rect] = Screen('openWindow', 1);
    try
        Eyelink('Initialize');
        try
            logfile = fopen('log.txt', 'w+');
            try
                results = doMyExperiment(arg);
            catch err
                try
                    fclose(logfile);
                catch err2
                    err = adderror(err2,err);
                    rethrow(err);
                end
            end
            fclose(logfile);
        catch err
            try
                Eyelink('Close');
            catch err2
                err = adderror(err2, err);
            end
            rethrow(err);
        end
        Eyelink('Close');
    catch err
        try
            Screen('Close', window);
        catch err2
            err = adderror(err2, err);
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