function init = screenGL(window)
    %function init = screenGL(window)
    %An initializer for the screen beginOpenGL/endOpenGL calls.
    %Requires a single window number as 'window'.
    
    init = @start;
    
    function [r, params] = start(params)
        Screen('BeginOpenGL', window);
        r = @stop;
        function stop()
            Screen('EndOpenGL', window);
        end
    end
end