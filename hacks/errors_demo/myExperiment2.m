function myExperiment(arg)
    %open the window on screen
    [window, rect] = Screen('openWindow', 0);
    
    %do your experiment...
    results = doMyExperiment(arg);
    
    Screen('Close', window);
end

function result = doMyExperiment(arg)
    if arg == 1
        printf('hello!\n');
    elseif arg == 2
        error('a:b', 'error!');
    end
    result = 'result!';
end