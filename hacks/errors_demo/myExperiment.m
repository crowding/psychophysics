function myExperiment(filename, arg)
 
    %open a file to record results...
    [fileHandle, message] = fopen(filename, 'w+')
    fprintf(fileHandle, 'Beginning experiment!\n');
    
    %do my experiment....
    result = doExperiment(fileHandle, arg);
    fprintf(fileHandle, 'Result: %d\n', result);
    
    %clean up...
    fprintf(fileHandle, 'End of experiment!\n');
    fclose(fileHandle);
end

function result = doExperiment(fileHandle, arg)
    if arg == 1
        fprintf(fileHandle, 'hello!\n');
    elseif arg == 2
        error('a:b', 'foobar');
    end
    result = 'result!';
end