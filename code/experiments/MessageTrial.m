function this = MessageTrial(varargin)
    message = 'Insert message here. Press space to continue.';
    key = 'Space';
    abortKey = 'q';
    color = [0 0 0];

    persistent init__;
    this = autoobject(varargin{:});
    
    function m = getMessage()
        %return the messagee that will be shown
        if isa(message, 'function_handle')
            m = message();
        else
            m = message;
        end
    end
    
    function [params, result] = run(params)
        m = getMessage();
        
        g = Text([0 0], m, color, 'centered', 1, 'visible', 1);
        r = RefreshTrigger();
        k = KeyDown();
        k.set(@endTrial, key);
        k.set(@abort, abortKey);
        
        if isfield(params.input, 'knob')
            i = {params.input.keyboard, params.input.knob};
            t = {r, k, KnobDown(@endTrial)};
        else
            i = {params.input.keyboard};
            t = {r, k};
        end
        
        main = mainLoop ...
            ( 'graphics', {g} ...
            , 'input',    i ...
            , 'triggers', t ...
            );

        main.go(params);
        
        function endTrial(h)
            result = struct('success', 1);
            g.setVisible(0); 
            r.set(main.stop, h.refresh + 1); %let a blank frame draw before stopping
        end
        
        function abort(h)
            result = struct('success', 0, 'abort', 1);
            g.setVisible(0);
            r.set(main.stop, h.refresh + 1); %let a blank frame draw before stopping            
        end
    end
end