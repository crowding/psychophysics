function this = MessageTrial(varargin)
    message = 'Insert message here. Press space to continue.';
    key = 'Space';
    color = [0 0 0];

    this = autoobject(varargin{:});
    
    function [params, result] = run(params)
        
        g = Text([0 0], message, color, 'centered', 1, 'visible', 1);
        r = RefreshTrigger();
        
        if isfield(params.input, 'knob')
            i = {params.input.keyboard, params.input.knob};
            t = {r, KeyDown(@endTrial, key), KnobDown(@endTrial)};
        else
            i = {params.input.keyboard};
            t = {r, KeyDown(@endTrial, key)};
        end
        
        main = mainLoop ...
            ( 'graphics', {g} ...
            , 'input',    i ...
            , 'triggers', t ...
            );

        main.go(params);
        
        function endTrial(h)
            result = struct('success', 1, 'keypress', 1);
            g.setVisible(0); 
            r.set(main.stop, h.refresh + 1); %let a blank frame draw before stopping
        end
    end
end