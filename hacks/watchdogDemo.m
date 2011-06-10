function this = watchdogDemo(varargin)
 
    text = Text('text', 'You have 5 seconds.', 'visible', 1, 'centered', 1);
    timeout = 5;
    
    persistent init__;
    this = autoobject(varargin{:});
    
    function params = run(params)
        trigger = Trigger();
        
        main = mainLoop...
            ( 'input', {params.input.keyboard}...
            , 'graphics', {text}...
            , 'triggers', trigger);
        
        %set the watchdog to reset as soon as the demo starts
        trigger.singleshot(atLeast('next', -Inf), @resetWatchdog);
        
        main.go(params);
        
        function resetWatchdog(status)
            %wait for either a press of the spacebar or a timeout.
            trigger.first...
                ( atLeast('next', status.next + timeout), main.stop,      'keyT' ...
                , keyIsDown('space'),                     @resetWatchdog, 'next');
            
            %update the status display
            text.setText(sprintf('You have until %s', datestr(now + timeout)));
        end
    end
    
    playDemo(this);
end